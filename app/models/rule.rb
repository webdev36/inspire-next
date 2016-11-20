class Rule < ActiveRecord::Base
  include Mixins::RuleSelectionSubscriber
  include Mixins::RuleDSL
  # attr_accessor :priority, :name, :description, :selection, :rule_if, :rule_then, :next_run_at, :active

  belongs_to :user
  has_many   :rule_activities, dependent: :destroy
  validates  :name, presence: true, uniqueness: { scope: [:user_id] }
  validates  :selection, presence: true
  validates  :rule_if, presence: true
  validates  :rule_then, presence: true

  scope :due,      ->           { where('next_run_at is NULL or next_run_at > ?', Time.now) }
  scope :active,   ->           { where(active: true) }
  scope :inactive, ->           { where(active: false) }
  scope :search,   -> (search)  { where('lower(name) LIKE ? OR lower(description) LIKE ?',"%#{search.to_s.downcase}%", "%#{search.to_s.downcase}%") }

  def process
    rule_then_objects
    log_rule_activity("Rule ran.")
    true
  end

  def self.valid_selectors(user)
    vs = []
    vs << 'subscribers_all'
    Channel.by_user(user).each do |channel|
      vs << "subscriber_in_channel_#{channel.id}"
    end
    vs
  end

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

  def valid_then_actions
    @valid_then_actions ||= begin
      vta = []
      Channel.by_user(user).pluck(:id).each do |cid|
        vta << "add_subscriber_to_channel_#{cid}"
        vta << "remove_subscriber_from_channel_#{cid}"
      end
      vta
    end
  end

  # logs activity
  def log_rule_activity(msg, acted_on_object = nil, success = true, opts = {})
    ra = self.rule_activities.new
    if acted_on_object
      ra.ruleable_type = acted_on_object.class.name
      ra.ruleable_id = acted_on_object.id
    end
    ra.success = true
    ra.message = msg
    ra.data = opts
    ra.save
    ra
  end

  def perform_then_action(ra, obj)
    if ra[:channel] && ra[:action] == 'add_to_channel'
      ChannelActions.add_to_channel(ra[:channel], obj, self)
      ra = log_rule_activity("Subscriber added to channel #{ra[:channel].id}", obj)
    elsif ra[:channel] && ra[:action] == 'remove_from_channel'
      ChannelActions.remove_from_channel(ra[:channel], obj, self)
      ra = log_rule_activity("Subscriber removed from channel #{ra[:channel].id}", obj)
    else
      ra = log_rule_activity("Rule perform failure: not found", obj.id, false)
      Rails.logger.info "warn=rule_perform_then_not_found rule_id=#{self.id} channel_id=#{ra[:channel].try(:id)}"
    end
  rescue => e
    ra = log_rule_activity("Rule perform failure: had error #{e.message}", obj, false)
    Rails.logger.info "warn=perform_then_action_raise rule_id=#{self.id} channel_id=#{ra[:channel].try(:id)} obj_id=#{obj.try(:id)} obj_class=#{obj.try(:class).try(:name)} message='#{e.message}'"
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
    return true if rule_if == '*'
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
        replacement = "\'#{replacement}\'"
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

  def selection_class
    if selection.start_with?('subscriber')
      'subscriber'
    #  elsif selection.start_with?('user')
    #    'user'
    #  elsif selection.start_with?('channel_group')
    #    'channel_group'
    #  elsif selection.start_with?('channel')
    #    'channel'
    else
      nil
    end
  end
end
