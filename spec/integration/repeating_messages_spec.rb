require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/Repeat messages' do
  it 'repeats message if no response is received and its configured to do so' do
    # a uesr setups a channel with repeatsing messages
    travel_to(2016, 9, 1, 10, 0, 0)
    setup_user_and_system
    @channel.relative_schedule = true
    @channel.save
    message = create_repeating_response_message(@channel)
    run_worker!

    # an hour later, we add a subscriber
    travel_to(2016, 9, 1, 10, 01, 0)
    @channel.subscribers.push @subscriber
    @channel.reload
    expect(@channel.subscribers.length == 1).to be_truthy
    run_worker!
    expect(@subscriber.delivery_notices.length == 0).to be_truthy

    # the first meessage is "Day 1, 12:00", so it SHOULD go now
    travel_to(2016, 9, 1, 12, 01, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 1).to be_truthy

    # the message count doesnt change, its not reminder time
    travel_to(2016, 9, 1, 12, 30, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 1).to be_truthy

    # the time is ready for the next reminder, it should be sent now.
    travel_to(2016, 9, 1, 13, 02, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 2).to be_truthy

    # the time not ready for the next reminder.
    travel_to(2016, 9, 1, 13, 30, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 2).to be_truthy

    # the time is ready for the next reminder, it should be sent now.
    travel_to(2016, 9, 1, 14, 02, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 3).to be_truthy
  end

  it 'does not send a reminder message when receiving a response' do
    # a uesr setups a channel with repeatsing messages
    travel_to(2016, 9, 1, 10, 0, 0)
    setup_user_and_system
    @channel.relative_schedule = true
    @channel.save
    @message = create_repeating_response_message(@channel)
    run_worker!
    # an hour later, we add a subscriber
    travel_to(2016, 9, 1, 11, 0, 0)
    @channel.subscribers.push @subscriber
    @channel.reload
    expect(@channel.subscribers.length == 1).to be_truthy
    run_worker!

    travel_to(2016, 9, 1, 12, 01, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 1).to be_truthy

    # the message count doesnt change, its not reminder time
    travel_to(2016, 9, 1, 12, 30, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 1).to be_truthy

    # an inbound message comes in from the subscriber
    travel_to(2016, 9, 1, 12, 35, 0)
    incoming_message = build :inbound_twilio_message
    incoming_message['From'] = @subscriber.phone_number
    incoming_message['To'] = @channel.tparty_keyword
    incoming_message['Body'] = "7"
    controller = TwilioController.new.send(:handle_request,incoming_message)
    expect(@subscriber.subscriber_responses.length == 1).to be_truthy
    @message.reload
    expect(@message.subscriber_responses.length == 1).to be_truthy

    # the time is ready for the next reminder, but it should not be sent
    # becuase the subscriber responded
    travel_to(2016, 9, 1, 13, 02, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 1).to be_truthy

    # and we still dont send one later
    travel_to(2016, 9, 1, 14, 30, 0)
    run_worker!
    @subscriber.reload
    expect(@subscriber.delivery_notices.length == 1).to be_truthy

  end
end
