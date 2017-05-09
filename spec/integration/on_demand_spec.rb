require 'spec_helper'

describe 'Integration/OnDemandWorking' do
  it 'handles on demand messages in a individual channel enviornment' do
    travel_to_string_time('September 1, 2016 10:00')
    setup_user_and_individually_scheduled_messages_relative_schedule
    @on_demand_channel = create :on_demand_messages_channel, user: @user,
                                tparty_keyword: @channel.tparty_keyword
    @channel.relative_schedule = true
    @channel.save
    @od_message_1 = create :message, channel: @on_demand_channel
    @dd_message_2 = create :message, channel: @on_demand_channel
    @on_demand_channel.keyword = 'iamondemand'
    @on_demand_channel.save
    @on_demand_channel.subscribers << @subscriber
    @message  = create_repeating_response_message(@channel, 'Day 1 12:00')
    @message2 = create_repeating_response_message(@channel, 'Day 2 12:00')
    @channel.keyword = 'iamthechannel'
    @channel.save
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

    # the first meessage is "Day 1, 13:00", so it SHOULD go now, but shouldn't
    # becuase we got a response
    expect {
      travel_to_string_time('September 2, 2016 13:00')
      run_worker!
      travel_to_same_day_at(13,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    expect {
      travel_to_string_time('September 2, 2016 14:00')
      run_worker!
      travel_to_same_day_at(14,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    # the first meessage is "Day 1, 12:00", so it SHOULD go now
    expect {
      travel_to_string_time('September 3, 2016 12:00')
      run_worker!
      travel_to_same_day_at(12,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    expect {
      travel_to_string_time('September 3, 2016 13:00')
      run_worker!
      travel_to_same_day_at(13,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    # the on demand message goes
    expect {
      travel_to_string_time('September 3, 2016 13:24')
      incoming_message = build :inbound_twilio_message
      incoming_message['From'] = @subscriber.phone_number
      incoming_message['To'] = @on_demand_channel.tparty_keyword
      incoming_message['Body'] = "iamondemand"
      controller = TwilioController.new.send(:handle_request, incoming_message)
    }.to change { DeliveryNotice.count }.by(1)

    # a reminder should not be sent, because it matched the correct message (newer)
    expect {
      travel_to_string_time('September 3, 2016 14:00')
      run_worker!
      travel_to_same_day_at(14,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)
  end

  it 'handles on demand messages in a channel-group enviornment' do
    travel_to_string_time('September 1, 2016 10:00')
    setup_user_channel_group_and_channel
    @on_demand_channel = create :on_demand_messages_channel, user: @user,
                                channel_group: @channel_group
    @channel.relative_schedule = true
    @channel.save
    @od_message_1 = create :message, channel: @on_demand_channel
    @dd_message_2 = create :message, channel: @on_demand_channel
    @on_demand_channel.keyword = 'iamondemand'
    @on_demand_channel.one_word = @on_demand_channel.keyword
    @on_demand_channel.save
    @message  = create_repeating_response_message(@channel, 'Day 1 12:00')
    @message2 = create_repeating_response_message(@channel, 'Day 2 12:00')
    @channel.keyword = 'iamthechannel'
    @channel.save
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

    # the first meessage is "Day 1, 13:00", so it SHOULD go now, but shouldn't
    # becuase we got a response
    expect {
      travel_to_string_time('September 2, 2016 13:00')
      run_worker!
      travel_to_same_day_at(13,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    expect {
      travel_to_string_time('September 2, 2016 14:00')
      run_worker!
      travel_to_same_day_at(14,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    # the first meessage is "Day 1, 12:00", so it SHOULD go now
    expect {
      travel_to_string_time('September 3, 2016 12:00')
      run_worker!
      travel_to_same_day_at(12,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    expect {
      travel_to_string_time('September 3, 2016 13:00')
      run_worker!
      travel_to_same_day_at(13,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)

    expect {
      travel_to_string_time('September 3, 2016 13:24')
      incoming_message = build :inbound_twilio_message
      incoming_message['From'] = @subscriber.phone_number
      incoming_message['To'] = @channel_group.tparty_keyword
      incoming_message['Body'] = "iamondemand"
      controller = TwilioController.new.send(:handle_request, incoming_message)
    }.to change { DeliveryNotice.count }.by(1)

    # a reminder should not be sent, because it matched the correct message (newer)
    expect {
      travel_to_string_time('September 3, 2016 14:00')
      run_worker!
      travel_to_same_day_at(14,03)
      run_worker!
    }.to change { DeliveryNotice.count }.by(1)
  end
end
