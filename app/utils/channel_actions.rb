class ChannelActions
  attr_accessor :channel, :subscriber, :originator

  def self.add_to_channel(channel, subscriber, originator)
    new(channel, subscriber, originator).add_to_channel
  end

  def self.remove_from_channel(channel, subscriber, originator)
    new(channel, subscriber, originator).remove_from_channel
  end

  def initialize(channel, subscriber, originator)
    @channel = channel
    @subscriber = subscriber
    @originator = originator
  end

  def originator_type
    @originator.class.name.to_s
  end

  def originator_id
    @originator.id
  end

  def originator_hash
    @originator_hash ||= {'originator_type' => originator_type, 'originator_id' => originator_id}
  end

  def build_action_notice(caption)
    an = ActionNotice.new(caption: caption, options: originator_hash)
    an.subscriber_id = subscriber.id
    an.channel_id = channel.id
    an.save
    an
  end

  def add_to_channel
    channel.subscribers << subscriber
    an = build_action_notice("Subscriber added to <a href='/channels/#{channel.id}'>#{channel.name}</a> channel.")
    Rails.logger.info "info=add_subscriber_to_channel class=#{originator_type} originator_id=#{originator_id} action_notice_id=#{an.id} subscriber_id=#{subscriber.id} channel_id=#{channel.id} action_notice_id=#{an.id}"
  end

  def remove_from_channel
    channel.subscribers.delete(subscriber)
    an = build_action_notice("Subscriber removed from <a href='/channels/#{channel.id}'>#{channel.name}</a> channel.")
    Rails.logger.info "info=remove_subscriber_from_channel class=#{originator_type} originator_id=#{originator_id} action_notice_id=#{an.id} subscriber_id=#{subscriber.id} channel_id=#{channel.id} action_notice_id=#{an.id}"
  end

end
