require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/Message Flooding' do
  describe '[individually_scheduled_message_channels]' do
    it '#relatively_scheduled' do
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
      travel_to(2016, 9, 20, 12, 1, 0)
      run_worker!

      # original message goes out
      expect(@subscriber.delivery_notices.count == 5).to be_truthy
      travel_to(2016, 9, 21, 12, 1, 0)
      run_worker!
      expect(@subscriber.delivery_notices.count == 6).to be_truthy

      # reminder message goes out
      travel_to(2016, 9, 21, 13, 2, 0)
      run_worker!
      expect(@subscriber.delivery_notices.count == 7).to be_truthy

      # second reminder message goes out
      travel_to(2016, 9, 21, 14, 2, 0)
      run_worker!
      expect(@subscriber.delivery_notices.count == 8).to be_truthy

            # second reminder message goes out
      travel_to(2016, 9, 21, 15, 2, 0)
      run_worker!
      expect(@subscriber.delivery_notices.count == 8).to be_truthy
      # later in the day, it sitll doesn't send old messages wehn past the
      # timer
      travel_to(2016, 9, 21, 20, 2, 0)
      run_worker!
      expect(@subscriber.delivery_notices.count == 8).to be_truthy
    end
  end
  describe '[scheduled messages channel]' do
    travel_to(2016, 9, 1, 10, 0, 0)

  end
end
