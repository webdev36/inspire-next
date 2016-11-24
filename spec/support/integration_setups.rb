require 'spec_helper'
require 'date'
require 'chronic'

def send_inbound_message_from_subscriber(subscriber, to, message)
  incoming_message = build :inbound_twilio_message
  incoming_message['From'] = subscriber.phone_number
  incoming_message['To'] = to
  incoming_message['Body'] = message
  controller = TwilioController.new.send(:handle_request, incoming_message)
end

def send_an_inbound_message_from_a_nonsubscriber(from_phone, to, message)
  incoming_message = build :inbound_twilio_message
  incoming_message['From'] = Subscriber.format_phone_number(from_phone)
  incoming_message['To'] = to
  incoming_message['Body'] = message
  controller = TwilioController.new.send(:handle_request,incoming_message)
end

def send_a_subscriber_response(sub, to, message)
  incoming_message = build :inbound_twilio_message
  incoming_message['From'] = sub.phone_number
  incoming_message['To'] = to
  incoming_message['Body'] = message
  controller = TwilioController.new.send(:handle_request,incoming_message)
end

def create_30_days_of_daily_response_messages(channel)
  (1..30).to_a.each do |daily_index|
    create_repeating_response_message(channel, "Day #{daily_index} 12:00")
  end
end

def create_30_days_of_daily_simple_messages(channel)
  (1..30).to_a.each do |daily_index|
    create_simple_message(channel, "Day #{daily_index} 12:00")
  end
end

def run_worker!
  TpartyScheduledMessageSender.new.perform
end

def setup_user_and_system
  @user = create :user
  @subscriber = create :subscriber, user: @user
  @channel = build :individually_scheduled_messages_channel, user: @user
  @channel.tparty_keyword = '+12025551212'
  @channel.relative_schedule = true
  @channel.save
end

def setup_user_and_individually_scheduled_messages_non_relative_schedule
  setup_user_and_system
  @channel.relative_schedule = false
  @channel.save
end

def setup_user_and_individually_scheduled_messages_relative_schedule
  setup_user_and_system
end

def setup_user_and_scheduled_messages_channel
  @user = create :user
  @subscriber = create :subscriber, user: @user
  @channel = build :scheduled_messages_channel, user: @user
  @channel.tparty_keyword = '+12025551212'
  @channel.save
end

def setup_user_channel_group_and_channel
  @user = create :user
  @subscriber = create :subscriber, user: @user
  @channel_group = create :channel_group, user: @user, tparty_keyword: '+12025551212'
  @channel = build :individually_scheduled_messages_channel, user: @user, channel_group: @channel_group
  @channel.relative_schedule = true
  @channel.save
end

def create_simple_message(channel = nil, schedule = 'Day 1 12:00')
  message = Message.new
  if channel
    message.channel_id = channel.id
  end
  message.caption = Faker::Lorem.sentence
  message.type = 'SimpleMessage'
  message.schedule = schedule
  message.active = true
  message.save
  message
end

def create_repeating_response_message(channel = nil, schedule = 'Day 1 12:00')
  message = Message.new
  if channel
    message.channel_id = channel.id
  end
  message.caption = 'How many drinks did you have today?'
  message.type = 'ResponseMessage'
  message.reminder_message_text = 'Reminder: How many drinks did you have today?'
  message.reminder_delay = 60
  message.repeat_reminder_message_text = 'Last Reminder: How many drinks did you have today?'
  message.repeat_reminder_delay = 120
  message.number_of_repeat_reminders = 1
  message.schedule = schedule
  message.active = true
  message.requires_response = true
  message.next_send_time = 1.minute.ago
  message.save
  message
end

def create_switching_channel_message(from_channel, to_channel, schedule = 'Minute 5')
  @switching_channel_message = build :switch_channel_action_message, channel: from_channel, schedule: schedule
  @switching_channel_message.action.as_text = "Switch channel to #{to_channel.id}"
  @switching_channel_message.action.data['to_channel_in_group'] = []
  @switching_channel_message.action.data['to_channel_out_group'] = [to_channel.id]
  @switching_channel_message.next_send_time = 1.minute.ago
  @switching_channel_message.save
  @switching_channel_message
end

def create_multi_switching_channel_message(from_channel, to_channels, channel_group, schedule = 'Minute 5')
  @switching_channel_message = build :switch_channel_action_message, channel: from_channel, schedule: schedule
  @switching_channel_message.action.as_text = "Switch channel to #{to_channels.first}"
  @switching_channel_message.action.data['to_channel_in_group'] = []
  @switching_channel_message.action.data['to_channel_out_group'] = []
  to_channels.each do |ch|
    if ch.channel_group_id == channel_group.id
      @switching_channel_message.action.data['to_channel_in_group'] << ch.id
    else
      @switching_channel_message.action.data['to_channel_out_group'] << ch.id
    end
  end
  @switching_channel_message.next_send_time = 1.minute.ago
  @switching_channel_message.save
  @switching_channel_message
end

