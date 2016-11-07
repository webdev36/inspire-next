require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/RecurringResponseIndividualMessages' do
  context 'non-relative messages' do
    it 'it sends a recurring response message based on a set schedule' do
      travel_to_time(Time.now - 30.days)
      travel_to_next_dow('Tuesday') # skip. it should run in 6 days
      travel_to_same_day_at(9,0)
      setup_user_and_individually_scheduled_messages_non_relative_schedule
      repeating_message = create :recurring_response_message_with_reminders, channel: @channel
      travel_to_same_day_at(10,0)
      subscriber = create :subscriber, user: @user
      @channel.subscribers << subscriber
      expect(@channel.subscribers.length == 1).to be_truthy
      run_worker!
      expect(subscriber.delivery_notices.count == 0).to be_truthy
      travel_to_next_dow('Monday')
      travel_to_same_day_at(8,0)
      run_worker!
      expect(subscriber.delivery_notices.length == 0).to be_truthy
      travel_to_same_day_at(9,46)
      @channel.send_scheduled_messages
      expect(subscriber.delivery_notices.length == 1).to be_truthy
    end
  end
end
