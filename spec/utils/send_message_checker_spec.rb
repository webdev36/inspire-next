require 'spec_helper'

describe SendMessageChecker do
  context 'non-relative (channel time) channel' do
    context 'recurring schedules (Every X Day of the week)' do
      it 'sends messages recurring, including reminder messages' do
        travel_to_time(Time.now - 30.days)
        travel_to_next_dow('Tuesday') # skip. it should run in 6 days
        travel_to_same_day_at(9,0)
        setup_user_and_individually_scheduled_messages_non_relative_schedule
        # set with a recurring message that recurs every week at 945am.
        repeating_message = create :recurring_response_message_with_reminders, channel: @channel
        subscriber = create :subscriber, user: @user
        @channel.subscribers << subscriber
        expect(@channel.subscribers.length == 1).to be_truthy
        travel_to_next_dow('Monday')
        travel_to_same_day_at(9,44)
        expect { run_worker! }.to change { DeliveryNotice.count }.by(1)

        # ensure it does not resend
        travel_to_same_day_at(9,45)
        expect { run_worker! }.to_not change { DeliveryNotice.count }

        # check that the message sends a repeat
        travel_to_same_day_at(10,46)
        expect { run_worker! }.to change { DeliveryNotice.count }.by(1)

        # travel to the last reminder
        travel_to_same_day_at(11,47)
        expect { run_worker! }.to change { DeliveryNotice.count }.by(1)

        travel_to_next_dow('Tuesday')
        travel_to_next_dow('Monday')
        travel_to_same_day_at(9,44)
        expect { run_worker! }.to change { DeliveryNotice.count }.by(1)
      end
    end
    context 'static schedule' do
      it 'on fixed date and time sends, including reminder messages' do
        travel_to_time(Chronic.parse('November 6, 2016 8pm'))
        setup_user_and_individually_scheduled_messages_non_relative_schedule
          # set with a recurring message that recurs every week at 945am.
        ['November 7, 2016 at 15:00', 'November 10, 2016 at 4pm'].each do |skedule|
          msg = build :static_response_message_with_reminders, channel: @channel
          msg.next_send_time = Chronic.parse(skedule)
          msg.schedule = nil
          msg.save
        end
        subscriber = create :subscriber, user: @user
        @channel.subscribers << subscriber
        expect(@channel.subscribers.length == 1).to be_truthy
        travel_to_time(Chronic.parse('November 7, 2016 3:00pm'))
        expect { run_worker! }.to change { DeliveryNotice.count }.by(1)
        travel_to_same_day_at(16,00)
        expect {
          run_worker!
          travel_to_same_day_at(16,03)
          run_worker!
         }.to change { DeliveryNotice.count }.by(1)
        travel_to_same_day_at(17,00)
        expect {
            run_worker!
            travel_to_same_day_at(17,03)
            run_worker!
          }.to change { DeliveryNotice.count }.by(1)
        travel_to_time(Chronic.parse('November 10, 2016 at 4pm'))
        expect { run_worker! }.to change { DeliveryNotice.count }.by(1)
        travel_to_same_day_at(17,00)
        expect {
          run_worker!
          travel_to_same_day_at(17,03)
          run_worker!
         }.to change { DeliveryNotice.count }.by(1)
        travel_to_same_day_at(18,00)
        expect {
            run_worker!
            travel_to_same_day_at(18,03)
            run_worker!
          }.to change { DeliveryNotice.count }.by(1)
      end
    end
  end
  context 'relative schedule (subscriber time) channels' do
    context 'recurring schedules (every week 1 monday at 8pm)' do
      it 'sends at the right times, including reminder messages' do
        travel_to_time(Time.now - 30.days)
        travel_to_next_dow('Tuesday') # skip. it should run in 6 days
        travel_to_same_day_at(9,0)
        setup_user_and_individually_scheduled_messages_relative_schedule
        # set with a recurring message that recurs every week at 945am.
        repeating_message = create :recurring_response_message_with_reminders, channel: @channel
        subscriber = create :subscriber, user: @user
        @channel.subscribers << subscriber
        expect(@channel.subscribers.length == 1).to be_truthy
        travel_to_next_dow('Monday')
        expect {
          travel_to_same_day_at(9,45)
          run_worker!
        }.to change { DeliveryNotice.count }.by(1)

        # ensure it does not resend
        expect {
          travel_to_same_day_at(9,46)
          run_worker!
        }.to_not change { DeliveryNotice.count }

        # check that the message sends a repeat
        expect {
          travel_to_same_day_at(10,45)
          run_worker!
          travel_to_same_day_at(10,48)
          run_worker!
        }.to change { DeliveryNotice.count }.by(1)

        # travel to the last reminder
        expect {
          travel_to_same_day_at(11,45)
          run_worker!
          travel_to_same_day_at(11,48)
          run_worker!
        }.to change { DeliveryNotice.count }.by(1)

        puts "STOP AND LOOK"
        expect {
          travel_to_next_dow('Monday')
          travel_to_same_day_at(9,45)
          run_worker!
        }.to change { DeliveryNotice.count }.by(1)
      end
    end
    context 'static/fixed schedules (Day 1 8:00, Week 1 Monday 8:0)' do
      it 'works for mixed dates and times, sending reminder messages' do
        travel_to_time(Chronic.parse('November 6, 2016 8pm'))
        # which is the 8th (nov 6 is a sunday)
        travel_to_next_dow('Tuesday')
        travel_to_same_day_at(9,0)
        setup_user_and_individually_scheduled_messages_relative_schedule
        ['Day 1 8:0', 'Week 1 Monday 8:0'].each do |skedule|
          msg = build :static_response_message_with_reminders, channel: @channel
          msg.schedule = skedule
          msg.save
        end
        subscriber = create :subscriber, user: @user
        @channel.subscribers << subscriber
        expect(@channel.subscribers.length == 1).to be_truthy
        expect {
          travel_to_next_dow('Wednesday')
          travel_to_same_day_at(8,00)
          run_worker!
        }.to change{ DeliveryNotice.count }.by(1)
        expect {
          travel_to_same_day_at(9,00)
          run_worker!
          travel_to_same_day_at(9,03)
          run_worker!
        }.to change{ DeliveryNotice.count }.by(1)
        expect {
          travel_to_same_day_at(10,00)
          run_worker!
          travel_to_same_day_at(10,03)
          run_worker!
        }.to change{ DeliveryNotice.count }.by(1)
        travel_to_time(Chronic.parse('November 15, 2016 8am'))
        expect {
          run_worker!
        }.to change{ DeliveryNotice.count }.by(1)
        expect {
          travel_to_same_day_at(9,00)
          run_worker!
          travel_to_same_day_at(9,03)
          run_worker!
        }.to change{ DeliveryNotice.count }.by(1)
        expect {
          travel_to_same_day_at(10,00)
          run_worker!
          travel_to_same_day_at(10,03)
          run_worker!
        }.to change{ DeliveryNotice.count }.by(1)
      end
    end
  end
end
