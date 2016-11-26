# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#

class SwitchChannelAction < Action
  include ActionView::Helpers
  before_validation :construct_action
  validate :check_action_text

  def type_abbr
    'Switch Subscriber'
  end

  def description
    'Switch a subscriber to a new channel'
  end

  def check_action_text
    if to_channel.blank?
      errors.add :as_text, 'missing channel id to switch'
    elsif !(as_text=~/^Switch channel to \d+$/)
      errors.add :as_text, "action is misformatted"
    end
  end

  def construct_action
    self.as_text = "Switch channel to #{to_channel}"
  end

  def invalid_subscriber_options_hash(opts)
    (opts[:subscribers].nil? || opts[:subscribers].empty? || (opts[:from_channel].nil? && opts[:channel].nil?))
  end

  def from_channels(opts)
    fc = []
    fc << opts[:from_channel] if opts[:from_channel]
    fc << opts[:channel] if opts[:channel] && fc.blank?
    Array(data['ensure_not_in_channels']).each do |ensure_remove_id|
      remove_chn = Channel.where(id: ensure_remove_id).limit(1).try(:first)
      if remove_chn
        fc << remove_chn unless fc.include?(remove_chn)
      end
    end
    fc
  end

  def channel_ids_to_add(opts)
    ids_to_add = []
    ids_to_add << to_channel
    Array(data['to_channel_in_group']).each {|id| ids_to_add << id }
    Array(data['to_channel_out_group']).each {|id| ids_to_add << id }
    ids_to_add = ids_to_add.map(&:to_i)
    Array(ids_to_add.uniq)
  end

  def to_channels(opts)
    tc = []
    channel_ids_to_add(opts).each do |cid|
      chn = Channel.where(:id => cid).try(:first)
      tc << chn if chn
    end
    tc
  end

  def execute(opts={})
    if invalid_subscriber_options_hash(opts)
      Rails.logger.info "info=no_subscribers class=switch_channel_action action_id=#{self.id} message_id=#{opts[:message].try(:[], 'id')}"
      return false
    end
    # who and what are we working on
    subscribers = opts[:subscribers]
    tc = to_channels(opts)
    fc = from_channels(opts)
    # let us know if there are 0, so we have a reference
    # if tc.length == 0 || fc.length == 0
    #  Rails.logger.info "info=nil_channel_on_switch_channel_action class=switch_channel_action action_id=#{self.id} to_count=#{tc.length} from_length=#{fc.length}"
    # end

    subscribers.each do |subx|
      execute_remove_subscriber_from_channels(fc, subx)
      execute_add_subscriber_to_channels(tc, subx)
    end
    return true
  rescue => e
    Rails.logger.error "error=raise class=switch_channel_action action_id=#{self.id} message_id=#{opts[:message].try(:[], 'id')} message='#{e.message}'"
    return false
  end

  def execute_remove_subscriber_from_channels(from_channels, subx)
    from_channels.each do |remove_channel|
      remove_from_channel(remove_channel, subx)
    end
  end

  def execute_add_subscriber_to_channels(to_channels, subx)
    to_channels.each do |add_channel|
      add_to_channel(add_channel, subx)
    end
  end

  # removes a subscriber from a channel, writing an acgtion notice for this specific action
  def remove_from_channel(ch, subx)
    ch.subscribers.delete(subx)
    an = ActionNotice.create(caption: "Subscriber removed from #{content_tag("a",ch.name,href:channel_path(ch))}", subscriber: subx)
    Rails.logger.info "info=remove_subscriber_from_channel severity=info class=switch_channel_action action_id=#{self.id} subscriber_id=#{subx.id} channel_id=#{ch.id} action_notice_id=#{an.id}"
    true
  rescue => e
    an = ActionErrorNotice.create(caption:'Error removing subscriber from #{content_tag("a",ch.name,href:channel_path(ch))}', subscriber:subx)
    Rails.logger.info "error=raise_when_removing_from_channel severity=error class=switch_channel_action action_id=#{self.id} channel_id=#{ch.id} subscriber_id=#{subx.id} action_error_notice_id=#{an.id} message='#{e.message}'"
    false
  end

  # adds a subscriber to a channel, writing a action notice for this specific action
  def add_to_channel(ch, subx)
    if ch.subscribers.include?(subx)
      an = ActionNotice.create(caption: "Subscriber verified in #{content_tag("a",ch.name,href:channel_path(ch))} skipped, already in channel", subscriber: subx)
      Rails.logger.info "info=skip_add_subscriber_to_channel severity=info class=switch_channel_action subscriber_id=#{subx.id} channel_id=#{ch.id} action_notice_id=#{an.id} message='Already in channel'"
    else
      ch.subscribers << subx
      an = ActionNotice.create(caption: "Subscriber added to #{content_tag("a",ch.name,href:channel_path(ch))}", subscriber: subx)
      Rails.logger.info "error=add_subscriber_to_channel severity=error class=switch_channel_action subscriber_id=#{subx.id} channel_id=#{ch.id} action_notice_id=#{an.id}"
    end
  end

  # checks the subscriber and the from channel, to see if its in it. If not, it goes and finds
  # the group (for the case of an onDemand channel), or returns nil, which will skip the processing.
  def get_from_channel_for_subscriber(subscriber, from_c)
    kosher = true
    subscriber_channel_to_remove = from_c
    if !from_c.subscribers.include?(subscriber)
      if ["OnDemandMessagesChannel"].include?(from_c.type)
        siblings = from_c.channel_group.channels.includes(:subscribers)
        siblings.each do |check_channel|
          if check_channel.subscribers.detect{ |cc_subscriber| cc_subscriber.phone_number == subscriber.phone_number }
            # set the found sibling channel to teh channel that we need ot remove teh sub from
            subscriber_channel_to_remove = check_channel
            break
          end
        end
      else
        subscriber_channel_to_remove = nil
        aen = ActionErrorNotice.create(caption:'Subscriber was not associated with source channel or channel group', subscriber:subscriber)
        Rails.logger.error "error=no_remove_channel_for_subscriber class=switch_channel_action subscriber_id=#{subscriber.id} channel_id=#{from_c.id} action_error_notice_id=#{aen.id}"
      end
    end
    subscriber_channel_to_remove
  end
end
