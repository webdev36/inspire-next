require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/Message Flooding' do
  context 'individually scheduled messages' do
    context 'relatively scheduled' do
      it 'does not flood' do
        travel_to(2016, 9, 1, 10, 0, 0)
        setup_user_and_system
        @channel.relative_schedule = true
        @channel.save
        (1..30).each do |day|
          message = create_repeating_response_message(@channel, "Day #{day} 12:00")
        end
        @channel.subscribers.push @subscriber
        @channel.reload
        expect(@channel.subscribers.length == 1).to be_truthy
        expect {
          travel_to(2016, 9, 20, 12, 1, 0)
          run_worker!
        }.to change { @subscriber.delivery_notices.count }.by(1)
      end
    end
    context 'statically scheduled' do
      it 'does not flood' do
        travel_to(2016, 9, 1, 10, 0, 0)
        setup_user_and_individually_scheduled_messages_non_relative_schedule

        expect {
          (1..30).each do |day|
            msg = build(:message, channel:@channel)
            msg.schedule = "Day #{day} 12:00"
            msg.save
          end
        }.to change { Message.count }.by(30)

        expect {
          @channel.subscribers.push @subscriber
        }.to change { Subscription.count }.by(1)

        expect {
          travel_to(2016, 9, 20, 12, 0, 0)
          run_worker!
        }.to change { DeliveryNotice.count }.by(1)
      end
    end
  end
  context 'scheduled messages channel' do
    let(:user)   { create(:user) }
    let(:channel){ create(:scheduled_messages_channel, user:user) }
    it "does not flood" do
      travel_to(2016, 9, 1, 10, 0, 0)
      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      subscriber
      20.times do
        create(:message, channel:channel)
      end
      travel_to(2016, 9, 20, 10, 0, 0)
      expect{ channel.send_scheduled_messages }.to change{ DeliveryNotice.count }.by(1)
    end
  end
  context 'ordered messages channel' do
    let(:user)   { create(:user) }
    let(:channel){ create(:ordered_messages_channel, user:user) }
    it "does not flood" do
      travel_to(2016, 9, 1, 10, 0, 0)
      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      subscriber
      30.times { create(:message, channel: channel) }
      expect{
        travel_to(2016, 9, 20, 10, 0, 0)
        channel.send_scheduled_messages
      }.to change{ DeliveryNotice.count }.by(1)
    end
  end
  context 'random messages channel' do
    let(:user)   { create(:user) }
    let(:channel){ create(:random_messages_channel, user:user) }
    it "does not flood" do
      travel_to(2016, 9, 1, 10, 0, 0)
      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      subscriber
      30.times { create(:message, channel: channel) }
      expect{
        travel_to(2016, 9, 20, 10, 0, 0)
        channel.send_scheduled_messages
      }.to change{ DeliveryNotice.count }.by(1)
    end
  end
end
