require 'spec_helper'

def send_a_subscriber_response(sub, to, message)
  incoming_message = build :inbound_twilio_message
  incoming_message['From'] = sub.phone_number
  incoming_message['To'] = to
  incoming_message['Body'] = message
  controller = TwilioController.new.send(:handle_request,incoming_message)
end

def travel_to(year, month, day, hour, minute, second)
  t = Time.local(year, month, day, hour, minute, second)
  Timecop.travel(t)
end

def travel_to_time(ruby_time)
  t = Time.local(ruby_time.year, ruby_time.month, ruby_time.day, ruby_time.hour, ruby_time.min, ruby_time.sec)
  Timecop.travel(t)
end

def travel_to_same_day_at(hour, minute)
  tn = Time.now
  t = Time.local(tn.year, tn.month, tn.day, hour, minute, 0)
  Timecop.travel(t)
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
  message.save
  message
end

