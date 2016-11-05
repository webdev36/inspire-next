require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/MatchSROutsideChannelGroup' do
  it 'matches a subscriber response outside the channel group' do
    original_time = Time.now.midnight
    travel_to_time(original_time - (32.days))
    setup_user_channel_group_and_channel
    create_30_days_of_daily_simple_messages(@channel)
    @outside_channel = build :individually_scheduled_messages_channel, user: @user, tparty_keyword: @channel_group.tparty_keyword
    @outside_channel.relative_schedule = true
    @outside_channel.save
    create_30_days_of_daily_response_messages(@outside_channel)

    # the next day, a subscriber registers and gets in channel and out of channel messages setup
    travel_to_time(original_time - 31.days)
    @subscriber = create :subscriber, user: @user
    @channel.subscribers << @subscriber
    @outside_channel.subscribers << @subscriber
    run_worker!
    base_add_time = Time.now
    # it should not have sent a message at midnight
    expect(@subscriber.delivery_notices.count == 0).to be_truthy

    [0].to_a.each do |dayz|
      travel_to_time(base_add_time + dayz.days)
      travel_to_same_day_at(11,0)
      run_worker!
      expect { run_worker! }.to_not change { @subscriber.delivery_notices.count }
      expect {
        travel_to_same_day_at(12,05)
        run_worker!
      }.to change {
        @subscriber.delivery_notices.count
      }.by(2)
      expect {
        travel_to_same_day_at(12,10)
        send_a_subscriber_response(@subscriber, @channel_group.tparty_keyword, Faker::Lorem.sentence)
      }.to change {
        SubscriberResponse.count
      }.by(1)
      travel_to_same_day_at(13,15)
      expect {
        run_worker!
      }.to_not change {
        @subscriber.delivery_notices.count
      }
      travel_to_same_day_at(14,20)
      expect {
        run_worker!
      }.to_not change {
        @subscriber.delivery_notices.count
      }
    end

    # the next day we don't send a response, and should get reminders
    [1].each do |dayz|
      travel_to_time(base_add_time + dayz.days)
      travel_to_same_day_at(11,0)
      run_worker!
      expect { run_worker! }.to_not change { @subscriber.delivery_notices.count }
      expect {
        travel_to_same_day_at(12,05)
        run_worker!
      }.to change {
        @subscriber.delivery_notices.count
      }.by(2)
      travel_to_same_day_at(13,10)
      expect {
        run_worker!
      }.to change {
        @subscriber.delivery_notices.count
      }.by(1)
      travel_to_same_day_at(14,15)
      expect {
        run_worker!
      }.to change {
        @subscriber.delivery_notices.count
      }.by(1)
      # its all done, it doesn't send any more reminder messages
      travel_to_same_day_at(15,20)
      expect {
        run_worker!
      }.to_not change {
        @subscriber.delivery_notices.count
      }
    end
  end
end
