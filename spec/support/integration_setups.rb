require 'spec_helper'

def travel_to(year, month, day, hour, minute, second)
  t = Time.local(year, month, day, hour, minute, second)
  Timecop.travel(t)
end

def travel_to_time(ruby_time)
  t = Time.local(ruby_time.year, ruby_time.month, ruby_time.day, ruby_time.hour, ruby_time.min, ruby_time.sec)
  Timecop.travel(t)
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
