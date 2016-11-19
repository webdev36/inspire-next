class Rule < ActiveRecord::Base
  # attr_accessor :priority, :name, :description, :selection, :rule_if, :rule_then, :next_run_at, :active

  scope :due, -> { where('next_run_at is NULL or next_run_at > ?', Time.now) }
  belongs_to :user
  has_many   :rule_activities, dependent: :destroy
  validates  :name, presence: true, uniqueness: { scope: [:user_id] }

  def selection_objects
    {
      'subscriber' => lambda { subscriber_selection_objects }
    }[selection_class]
  end

  def rule_then_objects
    rto = []
    rule_if_objects.each do |rifo|
      rule_then_actions.map { |ra| perform_then_action(ra, rifo) }
      rto << rifo
    end
    rto
  end

  def perform_then_action(ra, obj)
    if ra[:channel] && ra[:action] == 'add_to_channel'
      ChannelActions.add_to_channel(ra[:channel], obj, self)
    elsif ra[:channel] && ra[:action] == 'remove_from_channel'
      ChannelActions.remove_from_channel(ra[:channel], obj, self)
    else
      Rails.logger.info "warn=rule_perform_then_not_found rule_id=#{self.id} channel_id=#{ra[:channel].try(:id)}"
    end
  rescue => e
    Rails.logger.info "warn=perform_then_action_raise rule_id=#{self.id} channel_id=#{ra[:channel].try(:id)} obj_id=#{obj.id} obj_class=#{ob.class.name} message='#{e.message}'"
    false
  end

  # built to handle a larger set than we are initially dpeloying, gathers all
  # the stuff we need to perform each then actions
  def rule_then_actions
    rta = []
    rule_then.split(" ").each do |raw_rule_action|
      if raw_rule_action.include?('add_subscriber_to_channel_')
        rta << {:action => 'add_to_channel', :channel => Channel.where(id: raw_rule_action.split('_').last).try(:first)}
      elsif raw_rule_action.include?('remove_subscriber_from_channel_')
        rta << {:action => 'remove_from_channel', :channel => Channel.where(id: raw_rule_action.split('_').last).try(:first)}
      else
        Rails.logger.info "warn=unrecognized_then_rule raw_rule_action=#{raw_rule_action} rule_id=#{self.id}"
      end
    end
    rta
  end

  def rule_if_objects
    rifo = []
    Array(selection_objects.call).each do |so|
      rifo << so if rule_if_true_for_object(so)
    end
    rifo
  end

  # this evaluates the object after iternpolating it
  def rule_if_true_for_object(obj)
    ir = interpolated_rule_if(obj)
    eval(ir)
  rescue => e
    Rails.logger.info "warn=error_processing_if_rule rule_id=#{self.id} mesasge='#{e.message}'"
    false
  end

  def interpolated_rule_if(obj)
    pattern, lexicon = interpolation_pattern_lexion(obj)
    rule_if.gsub(pattern) do |mtch|
      replacement = lexicon[mtch]
      if [DateTime, Time, ActiveSupport::TimeWithZone].include?(replacement.class)
        replacement = replacement.to_i
      end
      replacement
    end
  end

  def interpolation_pattern_lexion(obj)
    lexicon = InterpolationHelper.to_hash(obj, user.id)
    terms = lexicon.keys.map { |key| Regexp.escape(key) }.join('|')
    pattern = Regexp.new(terms)
    [pattern, lexicon]
  end

  def subscriber_selection_objects
    if selection == 'subscribers_all'
      user.subscribers
    elsif selection.include?('subscriber_id_')
      sub_id = selection.gsub('subscriber_id_', '')
      user.subscribers.where(id: sub_id)
    elsif selection.include?('subscriber_in_channel_')
      chn_id = selection.gsub('subscriber_in_channel_', '')
      user.channels.find(chn_id).subscribers
    else
      []
    end
  end

  def selection_class
    if selection.start_with?('subscriber')
      'subscriber'
    elsif selection.start_with?('user')
      'user'
    elsif selection.start_with?('channel_group')
      'channel_group'
    elsif selection.start_with?('channel')
      'channel'
    else
      nil
    end
  end
end
