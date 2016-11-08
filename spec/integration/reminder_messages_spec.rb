require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/Reminder messages' do
  it 'reminder message send if no response is received' do
    # a uesr setups a channel with repeatsing messages
    travel_to_string_time('September 1, 2016 10:00')
    setup_user_and_individually_scheduled_messages_relative_schedule
    message = create_repeating_response_message(@channel)
    expect {
      run_worker!
    }.to_not change { DeliveryNotice.count }
    # an hour later, we add a subscriber
    expect {
      # an hour later, we add a subscrxiber
      travel_to_string_time('September 1, 2016 11:00')
      @channel.subscribers.push @subscriber
    }.to change { @channel.subscribers.length }.by(1)

    expect {
      run_worker!
    }.to_not change { DeliveryNotice.count }

    # the first meessage is "Day 1, 12:00", so it SHOULD go now
    expect {
      travel_to_string_time('September 2, 2016 12:00')
      run_worker!
      travel_to_same_day_at(12,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    # the message count doesnt change, its not reminder time
    expect {
      travel_to_same_day_at(12,30)
      run_worker!
    }.to_not change { DeliveryNotice.count }

    # the time is ready for the next reminder, it should be sent now.
    expect {
      travel_to_same_day_at(13,00)
      run_worker!
      travel_to_same_day_at(13,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    # the time not ready for the next reminder.
    expect {
      travel_to_same_day_at(13,30)
      run_worker!
    }.to_not change { DeliveryNotice.count }

    # the time is ready for the next reminder, it should be sent now.
    expect {
      travel_to_same_day_at(14,00)
      run_worker!
      travel_to_same_day_at(14,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)
  end

  it 'are not sent when receiving a response' do
    travel_to_string_time('September 1, 2016 10:00')
    setup_user_and_individually_scheduled_messages_relative_schedule
    @message = create_repeating_response_message(@channel)
    expect {
      run_worker!
    }.to_not change { DeliveryNotice.count }

    expect {
      # an hour later, we add a subscrxiber
      travel_to_string_time('September 1, 2016 11:00')
      @channel.subscribers.push @subscriber
    }.to change { @channel.subscribers.length }.by(1)

    expect {
      run_worker!
    }.to_not change { DeliveryNotice.count }

    # the first meessage is "Day 1, 12:00", so it SHOULD go now
    expect {
      travel_to_string_time('September 2, 2016 12:00')
      run_worker!
      travel_to_same_day_at(12,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    # the message count doesnt change, its not reminder time
    expect {
      travel_to_same_day_at(12,30)
      run_worker!
    }.to_not change { DeliveryNotice.count }

    # a subscriber sends a message
    expect {
      travel_to_string_time('September 2, 2016 12:34')
      incoming_message = build :inbound_twilio_message
      incoming_message['From'] = @subscriber.phone_number
      incoming_message['To'] = @channel.tparty_keyword
      incoming_message['Body'] = "7"
      controller = TwilioController.new.send(:handle_request,incoming_message)
    }.to change { SubscriberResponse.count }.by(1)

    # the first meessage is "Day 1, 13:00", so it SHOULD go now, but shouldn't
    # becuase we got a response
    expect {
      travel_to_string_time('September 2, 2016 13:00')
      run_worker!
      travel_to_same_day_at(13,03)
      run_worker!
    }.to_not change { DeliveryNotice.count }

    expect {
      travel_to_string_time('September 2, 2016 14:00')
      run_worker!
      travel_to_same_day_at(14,03)
      run_worker!
    }.to_not change { DeliveryNotice.count }
  end
end
