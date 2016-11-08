require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/RecurringResponseIndividualMessages' do
  context 'non-relative messages' do
    it 'sends a recurring response messages (same message weekly without reconfig)' do
      travel_to_string_time('September 6, 2016 9:00') # its a Tuesday
      setup_user_and_individually_scheduled_messages_non_relative_schedule
      repeating_message = create :recurring_response_message_with_reminders, channel: @channel

      expect {
        travel_to_same_day_at(10,0)
        subscriber = create :subscriber, user: @user
        @channel.subscribers << subscriber
      }.to change { Subscriber.count }.by(1)

      expect {
        run_worker!
      }.to_not change { DeliveryNotice.count }

      # its before the recurring window of time
      [1,2].each do |the_time|
        expect {
          travel_to_next_dow('Monday')
          travel_to_same_day_at(8,0)
          run_worker!
        }.to_not change { DeliveryNotice.count }

        expect {
          travel_to_same_day_at(9,45)
          run_worker!
          travel_to_same_day_at(9,48)
          run_worker!
        }.to change { DeliveryNotice.count }.by(1)

        expect {
          travel_to_same_day_at(10,25)
          run_worker!
        }.to_not change { DeliveryNotice.count }

        expect {
          travel_to_same_day_at(10,45)
          run_worker!
          travel_to_same_day_at(10,48)
          run_worker!
        }.to change { DeliveryNotice.count }.by(1)

        expect {
          travel_to_same_day_at(11,45)
          run_worker!
          travel_to_same_day_at(11,48)
          run_worker!
        }.to change { DeliveryNotice.count }.by(1)
      end
    end
  end
end
