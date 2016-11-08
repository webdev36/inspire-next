class SendMessageChecker
  attr_accessor :message, :subscriber

  def self.send_to_subscriber?(subscriber, message)
    helper = new(subscriber, message)
    helper.send_to_this_subscriber?
  end

  def initialize(subscriber, message)
    @message = message
    @subscriber = subscriber
  end

  def send_to_this_subscriber?
    # print_calc
    flag = false
    flag = valid_schedule? if passes_initial_checks?
    flag
  end

  def passes_initial_checks?
    !subscriber_added_to_channel_at.blank? && valid_message_for_sending_to_subscriber? &&
        channel.individual_messages_have_schedule?
  end

  # the relative schedule case is where the subscriber's subscribed time is the
  # basiss for callcuating if we send the message to teh subscriber or not
  def valid_schedule?
    return false if message_is_too_past_due_to_send_to_subscriber?
    return false if !message_is_due_to_be_sent_to_subscriber?
    true
  end

  # if the channel is relative time, then it should run with a base time of the
  # subscriber channel added time. If the channel is NOT a relative channel, then
  # it should calculate based on the channel time itself.
  def scheduled_time_at
    @scheduled_time_at ||= begin
      if channel.relative_schedule # to subscriber
        relative_scheduled_time
      else
        static_scheduled_time # to channel creation
      end
    end
  end

  # the static schedule time is where the subscriber subscribed time doesn't match
  # the messages are scheduled relative to an absolute date and time
  def static_scheduled_time
    @static_scheduled_time ||= message.next_occurrence(channel_created_at)
  end

  # when is this message scheduled to go to the subscriber in the relative case
  def relative_scheduled_time
    @relative_scheduled_time ||= message.next_occurrence(subscriber_added_to_channel_at)
  end

  def channel
    @channel ||= message.channel
  end

  def channel_created_at
    @channel_created_at ||= channel.created_at
  end

  # validates if its recurring, if we have recently sent a mesasge, if not then
  # we invalidate if we have sent this message already to the subscriber
  def valid_message_for_sending_to_subscriber?
    if message.has_recurring_schedule_field_data?
      !has_recently_been_sent_message?
    else
      !has_already_been_sent_message?
    end
  end

  def message_is_due_to_be_sent_to_subscriber?
    schedule_delta <= 240.0
  end

  # a recurring scheduler will return a nil if its not time to process. So,
  # if there is a nil, we set it to NOT NOW timewise
  def schedule_delta
    sd = 9999999999.0
    sd = (Time.now - scheduled_time_at).abs if scheduled_time_at
    sd
  end

  def message_is_too_past_due_to_send_to_subscriber?
    flag = true
    flag = scheduled_time_at < (Time.now - 24.hours) if scheduled_time_at
    flag
  end

  def subscriber_added_to_channel_at
    @subscriber_added_to_channel_at ||= Subscription.where(subscriber_id: subscriber.id, channel_id: self.channel.to_param).first.try(:created_at)
  end

  def has_already_been_sent_message?
    any_delivery_notice_for_message? || any_delivery_error_notice_for_message?
  end

  def has_recently_been_sent_message?
    recent_delivery_notice_for_message? || recent_delivery_error_notice_for_message?
  end

  def subscriber_added_to_channel_at
    Subscription.where(subscriber_id: subscriber.id, channel_id: channel.to_param).first.try(:created_at)
  end

  def any_delivery_notice_for_message?
    DeliveryNotice.of_primary_messages.where(message_id:message.id, subscriber_id:subscriber.id).exists?
  end

  def any_delivery_error_notice_for_message?
    DeliveryErrorNotice.of_primary_messages.where(message_id:message.id, subscriber_id:subscriber.id).exists?
  end

  def recent_delivery_notice_for_message?
    DeliveryNotice.of_primary_messages.recently_created.where(message_id:message.id, subscriber_id:subscriber.id).exists?
  end

  def recent_delivery_error_notice_for_message?
    DeliveryErrorNotice.of_primary_messages.recently_created.where(message_id:message.id, subscriber_id:subscriber.id).exists?
  end

  # helper method for troubleshooting. Prints all the main variables used in the calculations for
  # what to do with the message
  def print_calc
    puts ""
    puts "TimeNow: #{Time.now} MessageId: #{message.id} ChannelRelative? #{channel.relative_schedule}"
    puts "MsgSchedule: #{message.schedule} MsgNextSendAT:#{message.next_send_time} MsgRecurringSchedule:#{message.recurring_schedule}"
    puts "SubAddedToChannelAt: #{subscriber_added_to_channel_at} ChannelCreatedAt: #{channel_created_at}"
    puts "ScheduledAt: #{scheduled_time_at} Schedule Delta: #{schedule_delta}"
    puts ""
  end

end
