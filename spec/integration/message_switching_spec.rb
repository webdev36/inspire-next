require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/MessageSwitching' do
  it 'switches as expected for a single channel with MO subscription enabled' do
    travel_to_same_day_at(9,00)
    setup_user_and_system
    @channel.name = "Source Channel"
    @channel.keyword = '35k9'
    @channel.save
    create_simple_message(@channel, 'Minute 1')
    # setup where we are switching to
    destination_channel = create :individually_scheduled_messages_channel,
                                 user: @user,
                                 name: 'Destination channel',
                                 tparty_keyword: @channel.tparty_keyword,
                                 relative_schedule: true
    destination_channel
    create_simple_message(destination_channel, 'Minute 1')
    # setup teh swtichign channel message
    create_switching_channel_message(@channel, destination_channel, 'Minute 2')

    travel_to_same_day_at(10,00)
    send_an_inbound_message_from_a_nonsubscriber('+12029876543', @channel.tparty_keyword, '35k9 start')
    [5, 10, 15, 20, 25].each do |minute|
      travel_to_same_day_at(10, minute)
      run_worker!
    end
    new_sub = Subscriber.find_by_phone_number('+12029876543')
    expect(new_sub.channels.map(&:id).include?(destination_channel.id)).to be_truthy
    expect(new_sub.delivery_notices.length == 2).to be_truthy
  end

  it 'switches as expected inside a group with MO subscription to channel group, not channel' do
    travel_to_same_day_at(9,00)
    setup_user_channel_group_and_channel
    @channel.name = "Source Channel"
    @channel.save
    @channel_group.default_channel_id = @channel.id
    @channel_group.name = 'Channel Group Test'
    @channel_group.keyword = '35k9'
    @channel_group.save
    @channel.save
    create_simple_message(@channel, 'Minute 1')
    # setup where we are switching to
    destination_channel = create :individually_scheduled_messages_channel,
                                 user: @user,
                                 name: 'Destination channel',
                                 channel_group: @channel_group,
                                 relative_schedule: true
    create_simple_message(destination_channel, 'Minute 1')
    # setup teh swtichign channel message
    create_switching_channel_message(@channel, destination_channel, 'Minute 2')
    travel_to_same_day_at(10,00)
    send_an_inbound_message_from_a_nonsubscriber('+12029876543', @channel_group.tparty_keyword, '35k9 start')
    [5, 10, 15, 20, 25].each do |minute|
      travel_to_same_day_at(10, minute)
      run_worker!
    end
    new_sub = Subscriber.find_by_phone_number('+12029876543')
    expect(new_sub.channels.map(&:id).include?(destination_channel.id)).to be_truthy
    expect(new_sub.delivery_notices.length == 2).to be_truthy
  end

  it 'multiswitches' do
    travel_to_same_day_at(9,00)
    setup_user_channel_group_and_channel
    @channel.name = "Source Channel"
    @channel.save
    @channel_group.default_channel_id = @channel.id
    @channel_group.name = 'Channel Group Test'
    @channel_group.keyword = '35k9'
    @channel_group.save
    @channel.save
    create_simple_message(@channel, 'Minute 1')
    # setup where we are switching to
    destination_channel = create :individually_scheduled_messages_channel,
                                 user: @user,
                                 name: 'Destination channel',
                                 channel_group: @channel_group,
                                 relative_schedule: true
    create_simple_message(destination_channel, 'Minute 1')

    destination_channel_2 = create :individually_scheduled_messages_channel,
                                 user: @user,
                                 name: 'Destination channel 2',
                                 tparty_keyword: @channel_group.tparty_keyword,
                                 relative_schedule: true

    create_simple_message(destination_channel_2, 'Minute 1')

    # setup the multi-switching message
    create_multi_switching_channel_message(@channel, [destination_channel, destination_channel_2], @channel_group, 'Minute 2')

    travel_to_same_day_at(10,00)
    send_an_inbound_message_from_a_nonsubscriber('+12029876543', @channel_group.tparty_keyword, '35k9 start')
    [5, 10, 15, 20, 25].each do |minute|
      travel_to_same_day_at(10, minute)
      run_worker!
    end
    new_sub = Subscriber.find_by_phone_number('+12029876543')
    expect(new_sub.channels.map(&:id).include?(destination_channel.id)).to be_truthy
    expect(new_sub.channels.map(&:id).include?(destination_channel_2.id)).to be_truthy
    expect(new_sub.delivery_notices.count == 3).to be_truthy
  end

end
