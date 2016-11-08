# == Schema Information
#
# Table name: channels
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  user_id           :integer
#  type              :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  keyword           :string(255)
#  tparty_keyword    :string(255)
#  next_send_time    :datetime
#  schedule          :text
#  channel_group_id  :integer
#  one_word          :string(255)
#  suffix            :string(255)
#  moderator_emails  :text
#  real_time_update  :boolean
#  deleted_at        :datetime
#  relative_schedule :boolean
#  send_only_once    :boolean          default(FALSE)
#

require 'spec_helper'

describe IndividuallyScheduledMessagesChannel do
  describe '#factory works' do
    subject { super().factory works }
    it do
    expect(build(:individually_scheduled_messages_channel)).to be_valid
  end
  end
  describe "#" do
    let(:user) {create(:user)}
    let(:channel) {create(:individually_scheduled_messages_channel,user:user)}
    subject {channel}

    describe '#has_schedule?' do
      subject { super().has_schedule? }
      it {is_expected.to be_falsey}
    end

    describe '#sequenced?' do
      subject { super().sequenced? }
      it { is_expected.to be_falsey}
    end

    describe '#broadcastable?' do
      subject { super().broadcastable? }
      it { is_expected.to be_falsey }
    end

    describe '#type_abbr' do
      subject { super().type_abbr }
      it {is_expected.to eq('Ind. Scheduled')}
    end

    it "group_subscribers_by_message groups messages with pending_send" do
      m1 = create(:message,channel:channel,next_send_time: 1.day.ago)
      m2 = create(:message,channel:channel,next_send_time: 1.minute.ago)
      m3 = create(:message,channel:channel)
      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      s3 = create(:subscriber,user:user)
      channel.subscribers << s1
      channel.subscribers << s2
      msh = subject.group_subscribers_by_message
      expect(msh.length).to eq(1)
      expect(msh.has_key?(m1.id)).to be_falsey
      expect(msh[m2.id].to_a.map(&:id).sort).to match_array([s1,s2].map(&:id).sort)
    end

    it "for messages with relative_schedule, the group_subscribers_by_message groups correctly" do
      channel.relative_schedule = true
      channel.save
      travel_to_string_time('January 20, 2014 08:00')
      m1 = create(:message, channel: channel,
                            relative_schedule_type:'Minute',
                            relative_schedule_number: '20')
      m2 = create(:message, channel:channel,
                            relative_schedule_type:'Week',
                            relative_schedule_number:1,
                            relative_schedule_day:'Thursday',
                            relative_schedule_hour:19,
                            relative_schedule_minute:'00')
      m3 = create(:message, channel: channel,
                            relative_schedule_type:'Week',
                            relative_schedule_number:1,
                            relative_schedule_day:'Friday',
                            relative_schedule_hour:19,
                            relative_schedule_minute:'00')

      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      s3 = create(:subscriber,user:user)
      expect {
        channel.subscribers << s1
        channel.subscribers << s2
        channel.subscribers << s3
      }.to change { Subscription.count }.by(3)

      create(:delivery_notice, subscriber:s1, message: m1)

      travel_to_string_time("January 20, 2014, 8:20")
      create(:delivery_notice, subscriber:s1, message: m1)
      msh = subject.group_subscribers_by_message
      expect(msh.length).to eq(1)
      expect(msh[m1.id].to_a.map(&:id).sort).to match_array([s2,s3].map(&:id).sort)

      travel_to_next_dow('Thursday')
      travel_to_next_dow('Thursday')
      create(:delivery_notice, subscriber:s3, message: m2)
      travel_to_same_day_at(19,00)
      msh = subject.group_subscribers_by_message
      expect(msh.length).to eq(1)
      expect(msh[m2.id].to_a.map(&:id).sort).to match_array([s1,s2].map(&:id).sort)

      travel_to_next_dow('Friday')
      travel_to_same_day_at(19,00)
      msh = subject.group_subscribers_by_message
      expect(msh.length).to eq(1)
      expect(msh[m3.id].to_a.map(&:id).sort).to match_array([s1,s2,s3].map(&:id).sort)
    end

    it "with absolute schedule makes the messages inactive once sent" do
      m1 = create(:message,channel:channel,next_send_time:1.day.ago)
      m2 = create(:message,channel:channel,next_send_time:2.days.ago)
      m3 = create(:message,channel:channel,next_send_time:2.days.ago)
      subject.perform_post_send_ops({m1.id=>[],m2.id=>[]})
      expect(m1.reload.active).to eq(false)
      expect(m2.reload.active).to eq(false)
      expect(m3.reload.active).to eq(true)
    end

    it "reset_next_send_time should make this channel due for send again" do
      subject.reset_next_send_time
      expect(subject.next_send_time).to be < Time.now
    end

    it "send_scheduled_messages sends messages to time not in the distant past" do
      m1 = create(:message, channel:channel, next_send_time:1.day.ago )
      m2 = create(:message, channel:channel, next_send_time:1.minute.ago)
      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      channel.subscribers << s1
      channel.subscribers << s2
      d1 = double.as_null_object
      allow(MessagingManager).to receive(:new_instance){ d1 }
      ma = []
      allow(d1).to receive(:broadcast_message){ |message,subscribers|
        expect(subscribers.to_a).to match_array([s1,s2])
        ma << message
      }
      subject.send_scheduled_messages
      expect(ma.map(&:id).sort).to match_array([Message.find(m2.id)].map(&:id).sort)
    end

    it "runs on a relative weekly schedule" do
      travel_to_string_time('January 1, 2014, 10:00')
      user = create(:user)
      channel_group = create(:channel_group, user:user)
      channel       = create(:individually_scheduled_messages_channel,
                              name:'TMAP-M', user:user,
                              keyword:'group1')
      channel.relative_schedule = true
      channel.save
      subscriber = create(:subscriber, user: user)

      msg0 = create(:message,channel:channel,title:'',caption:'Welcome to TMap',
        relative_schedule_type:'Minute',
        relative_schedule_number:1)

      msg1 = create(:response_message,channel:channel,title:'',caption:'Who is the designated driver',
        relative_schedule_type:'Week',
        relative_schedule_number:1,
        relative_schedule_day:'Thursday',
        relative_schedule_hour:19,
        relative_schedule_minute:0,
        reminder_message_text:'Was that message helpful?',
        repeat_reminder_message_text:'Sorry to bug you, but was it helpful?'
      )

      msg2 = create(:response_message,channel:channel,title:'',caption:'Dont let the pregame ruin the big game',
        relative_schedule_type:'Week',
        relative_schedule_number:1,
        relative_schedule_day:'Friday',
        relative_schedule_hour:19,
        relative_schedule_minute:0,
        reminder_message_text:'Was that message helpful?',
        repeat_reminder_message_text:'Sorry to bug you, but was it helpful?'
      )

      msg3 = create(:response_message,channel:channel,title:'',caption:'The fun will be over too soon',
        relative_schedule_type:'Week',
        relative_schedule_number:1,
        relative_schedule_day:'Friday',
        relative_schedule_hour:21,
        relative_schedule_minute:0
      )

      channel.subscribers << subscriber
      # the first time it runs it sends a mesage to the subscriber
      travel_to_string_time('January 1, 2014 10:01')
      expect { run_worker! }.to change{ DeliveryNotice.count }.by(1)

      # but the messages are sccheduled after this, so no message goes
      travel_to_string_time('January 2, 2014 18:00')
      expect { run_worker! }.to_not change{ DeliveryNotice.count }

      # message 1, the first week, on Thursday at 7pm
      travel_to_string_time('January 11, 2014 19:00')
      expect { run_worker! }.to change { DeliveryNotice.count }.by(1)

      travel_to_string_time('January 12, 2014 19:00')
      expect { run_worker! }.to change { DeliveryNotice.count }.by(1)
    end

    it "is always pending_send" do
      channel.reload
      expect(Channel.pending_send).to be_include subject
    end

    describe "find_target_time" do
      let(:from_time) {Time.new(2014)} #Wednesday
      it "returns right target time when type is minute" do
        expect(subject.find_target_time('Minute 20',from_time)).to eq(Time.new(2014,1,1,0,20))
      end
      it "returns right target time when type is hour" do
        expect(subject.find_target_time('Hour 2 15',from_time)).to eq(Time.new(2014,1,1,1,15))
      end
      it "returns right target time when type is day" do
        expect(subject.find_target_time('Day 2 18:15',from_time)).to eq(Time.new(2014,1,2,18,15))
      end
      it "returns right target time when type is day and hour has passed" do
        from_time = Time.new(2014,1,1,10,0)
        expect(subject.find_target_time('Day 1 08:15',from_time)).to eq(Time.new(2014,1,2,8,15))
      end
      it "returns right target time when type is day and hour has not passed" do
        from_time = Time.new(2014,1,1,10,0)
        expect(subject.find_target_time('Day 1 18:15',from_time)).to eq(Time.new(2014,1,1,18,15))
      end
      it "returns right target time when type is week" do
        expect(subject.find_target_time('Week 2 Tuesday 18:15',from_time)).to eq(Time.new(2014,1,14,18,15))
      end
      it "returns right target time when type is week and same week" do
        expect(subject.find_target_time('Week 1 Thursday 18:15',from_time)).to eq(Time.new(2014,1,2,18,15))
      end
      it "returns right target time when type is 1 week and day has passed" do
        expect(subject.find_target_time('Week 1 Tuesday 18:15',from_time)).to eq(Time.new(2014,1,7,18,15))
      end
      it "returns right target time when type is week and we are scheduling on the same day and time is past" do
        from_time = Time.new(2014,1,1,12,30)
        expect(subject.find_target_time("Week 1 Wednesday 10:00",from_time)).to eq(Time.new(2014,1,8,10,0))
      end
      it "returns right target time when type is week and we are scheduling on the same day and time is in future" do
        from_time = Time.new(2014,1,1,12,30)
        expect(subject.find_target_time("Week 1 Wednesday 16:00",from_time)).to eq(Time.new(2014,1,1,16,0))
      end
    end

    describe "reverse_engineer_subscription_time" do
      it "works fine when there are no previous sends" do
        prev_sends = [];
        expect(subject.reverse_engineer_subscription_time(prev_sends)).to be_nil
      end
      it "works when there is only one weekly message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Week 1 Monday 10:00'];
        expect(subject.reverse_engineer_subscription_time(prev_sends)).to eq(Time.new(2014,1,6,7,5,0))
        Timecop.return
      end
      it "works when there is one weekly and day 1 message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Day 1 20:00','Week 1 Monday 10:00'];
        expect(subject.reverse_engineer_subscription_time(prev_sends)).to eq(Time.new(2014,1,5,19,05,0))
        Timecop.return
      end
      it "works when there is one weekly and 2 days(second day today) message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Day 1 20:00','Day 2 08:00','Week 1 Monday 10:00'];
        expect(subject.reverse_engineer_subscription_time(prev_sends)).to eq(Time.new(2014,1,5,19,5,0))
        Timecop.return
      end
      it "works when there is one weekly and 2 days(second day yesterday) message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Day 1 20:00','Day 2 18:00','Week 1 Monday 10:00'];
        expect(subject.reverse_engineer_subscription_time(prev_sends)).to eq(Time.new(2014,1,4,22,5,0))
        Timecop.return
      end
      it "works when there is one weekly and full week daily message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Day 1 20:00','Day 2 18:00','Day 3 10:00', 'Day 4 12:00',
          'Day 5 21:00','Day 6 19:00','Day 7 12:00','Week 1 Monday 10:00'];
        expect(subject.reverse_engineer_subscription_time(prev_sends)).to eq(Time.new(2013,12,30,22,5,0))
        Timecop.return
      end
    end
    describe "when readding subscriber to the channel" do
      before do
        @subs = create(:subscriber,user:user)
        msg1 = create(:message,channel:channel,schedule:'Day 1 20:00')
        msg2 = create(:message,channel:channel,schedule:'Week 1 Monday 10:00')
        deleted_message = create(:message,channel:channel,schedule:'Day 4 22:00')
        dn1 = create(:delivery_notice,subscriber:@subs,message:msg1)
        dn2 = create(:delivery_notice,subscriber:@subs,message:msg2)
        dn3 = create(:delivery_notice,subscriber:@subs,message:deleted_message)
        deleted_message.destroy
      end
      it "alters the subscription time to account for the messages already sent" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
          channel.subscribers << @subs
          subscription = Subscription.where(subscriber_id:@subs.id,channel_id:channel.id).first
          expect(subscription.created_at).to eq(Time.new(2014,1,5,19,5,0))
        Timecop.return
      end
      it "does not alter the subscription time if the subscriber is added for first time" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
          new_sub = create(:subscriber,user:user)
          channel.subscribers << new_sub
          subscription = Subscription.where(subscriber_id:new_sub.id,channel_id:channel.id).first
          expect(subscription.created_at).to eq(Time.new(2014,1,6,10,5,0))
        Timecop.return
      end
    end
  end


end
