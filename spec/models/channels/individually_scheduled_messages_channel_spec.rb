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
  its "factory works" do
    expect(build(:individually_scheduled_messages_channel)).to be_valid
  end
  describe "#" do
    let(:user) {create(:user)}
    let(:channel) {create(:individually_scheduled_messages_channel,user:user)}
    subject {channel}
    its(:has_schedule?) {should be_false}
    its(:sequenced?) { should be_false}
    its(:broadcastable?) { should be_false}
    its(:type_abbr){should == 'Ind. Scheduled'}

    it "group_subscribers_by_message groups messages with pending_send" do
      m1 = create(:message,channel:channel,next_send_time:1.day.ago)
      m2 = create(:message,channel:channel,next_send_time:1.minute.ago)
      m3 = create(:message,channel:channel)
      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      s3 = create(:subscriber,user:user)
      channel.subscribers << s1
      channel.subscribers << s2
      msh = subject.group_subscribers_by_message
      msh.length.should == 2
      msh[m1.id].to_a.should =~ [s1,s2]
      msh[m2.id].to_a.should =~ [s1,s2]
    end

    it "for messages with relative_schedule, the group_subscribers_by_message groups correctly" do
      channel.relative_schedule = true
      channel.save
      m1 = create(:message,channel:channel,relative_schedule_type:'Minute',
      relative_schedule_number: '20')
      m2 = create(:message,channel:channel,relative_schedule_type:'Week',
        relative_schedule_number:1,relative_schedule_day:'Thursday',
        relative_schedule_hour:19,relative_schedule_minute:'00')
      m3 = create(:message,channel:channel,relative_schedule_type:'Week',
        relative_schedule_number:1,relative_schedule_day:'Friday',
        relative_schedule_hour:19,relative_schedule_minute:'00')
      Timecop.freeze(Time.new(2014,1,20))
      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      s3 = create(:subscriber,user:user)
      channel.subscribers << s1
      channel.subscribers << s2
      channel.subscribers << s3
      Timecop.freeze(Time.new(2014,1,23,19,10))
      create(:delivery_notice,subscriber:s1,message:m1)
      create(:delivery_notice,subscriber:s3,message:m2)
      msh = subject.group_subscribers_by_message
      msh.length.should == 2
      msh[m1.id].to_a.should =~ [s2,s3]
      msh[m2.id].to_a.should =~ [s1,s2]
      Timecop.return
    end

    it "with absolute schedule makes the messages inactive once sent" do
      m1 = create(:message,channel:channel,next_send_time:1.day.ago)
      m2 = create(:message,channel:channel,next_send_time:2.days.ago)
      m3 = create(:message,channel:channel,next_send_time:2.days.ago)
      subject.perform_post_send_ops({m1.id=>[],m2.id=>[]})
      m1.reload.active.should == false
      m2.reload.active.should == false
      m3.reload.active.should == true
    end

    it "reset_next_send_time should make this channel due for send again" do
      subject.reset_next_send_time
      subject.next_send_time.should < Time.now
    end

    it "send_scheduled_messages sends messages whose next_send_time is in past" do
      m1 = create(:message,channel:channel,next_send_time:1.day.ago)
      m2 = create(:message,channel:channel,next_send_time:1.minute.ago)
      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      channel.subscribers << s1
      channel.subscribers << s2
      d1 = double.as_null_object
      MessagingManager.stub(:new_instance){d1}
      ma = []
      d1.stub(:broadcast_message){ |message,subscribers|
        subscribers.to_a.should =~ [s1,s2]
        ma << message
      }
      subject.send_scheduled_messages
      ma.should =~ [Message.find(m1),Message.find(m2)]
    end

    it "tmap runs on a relative weekly schedule" do
      Timecop.travel(Time.new(2014,1,1,10,0))
      user = create(:user)
      channel_group = create(:channel_group,user:user)
      channel = create(:individually_scheduled_messages_channel,name:'TMAP-M', user:user,
        keyword:'group1')
      channel.relative_schedule = true
      channel.save
      subscriber = create(:subscriber,user:user)
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
      Timecop.travel(Time.new(2014,1,1,11,0))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }.by 1

      # but the messages are sccheduled after this, so no message goes
      Timecop.travel(Time.new(2014,1,2,18,00))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to_not change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }

      # message 1, the first week, on Thursday at 7pm
      Timecop.travel(Time.new(2014,1,2,19,00,01))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }.by 1

      Timecop.travel(Time.new(2014,1,2,19,01,30))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }.by 1

      Timecop.travel(Time.new(2014,1,2,19,30,30))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }.by 1

      Timecop.travel(Time.new(2014,1,3,19,00,01))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }.by 1

      Timecop.travel(Time.new(2014,1,3,19,01,30))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }.by 1
      #Breaks MVC, but this test case is a bit over-ambitious for a model anyway
      params={}
      params["Body"]="#{channel.tparty_keyword} #{channel.keyword} yes"
      params["From"]=subscriber.phone_number
      resp =  TwilioController.new.send(:handle_request,params)
      Timecop.travel(Time.new(2014,1,3,19,30,30))
      expect {
          TpartyScheduledMessageSender.new.perform
          }.to_not change{
            DeliveryNotice.where(subscriber_id:subscriber).count
          }

      Timecop.travel(Time.new(2014,1,3,21,00,01))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }.by 1

      params={}
      params["Body"]="#{channel.tparty_keyword} #{channel.keyword} yes"
      params["From"]=subscriber.phone_number
      TwilioController.new.send(:handle_request,params)

      Timecop.travel(Time.new(2014,1,3,21,01,30))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to_not change{
          DeliveryNotice.where(subscriber_id:subscriber).count
        }
      Timecop.travel(Time.new(2014,1,3,21,30,30))
      expect {
          TpartyScheduledMessageSender.new.perform
          }.to_not change{
            DeliveryNotice.where(subscriber_id:subscriber).count
          }
    end

    it "is always pending_send" do
      channel.reload
      Channel.pending_send.should be_include subject
    end

    describe "find_target_time" do
      let(:from_time) {Time.new(2014)} #Wednesday
      it "returns right target time when type is minute" do
        subject.find_target_time('Minute 20',from_time).should == Time.new(2014,1,1,0,20)
      end
      it "returns right target time when type is hour" do
        subject.find_target_time('Hour 2 15',from_time).should == Time.new(2014,1,1,1,15)
      end
      it "returns right target time when type is day" do
        subject.find_target_time('Day 2 18:15',from_time).should == Time.new(2014,1,2,18,15)
      end
      it "returns right target time when type is day and hour has passed" do
        from_time = Time.new(2014,1,1,10,0)
        subject.find_target_time('Day 1 08:15',from_time).should == Time.new(2014,1,2,8,15)
      end
      it "returns right target time when type is day and hour has not passed" do
        from_time = Time.new(2014,1,1,10,0)
        subject.find_target_time('Day 1 18:15',from_time).should == Time.new(2014,1,1,18,15)
      end
      it "returns right target time when type is week" do
        subject.find_target_time('Week 2 Tuesday 18:15',from_time).should == Time.new(2014,1,14,18,15)
      end
      it "returns right target time when type is week and same week" do
        subject.find_target_time('Week 1 Thursday 18:15',from_time).should == Time.new(2014,1,2,18,15)
      end
      it "returns right target time when type is 1 week and day has passed" do
        subject.find_target_time('Week 1 Tuesday 18:15',from_time).should == Time.new(2014,1,7,18,15)
      end
      it "returns right target time when type is week and we are scheduling on the same day and time is past" do
        from_time = Time.new(2014,1,1,12,30)
        subject.find_target_time("Week 1 Wednesday 10:00",from_time).should == Time.new(2014,1,8,10,0)
      end
      it "returns right target time when type is week and we are scheduling on the same day and time is in future" do
        from_time = Time.new(2014,1,1,12,30)
        subject.find_target_time("Week 1 Wednesday 16:00",from_time).should == Time.new(2014,1,1,16,0)
      end
    end

    describe "reverse_engineer_subscription_time" do
      it "works fine when there are no previous sends" do
        prev_sends = [];
        subject.reverse_engineer_subscription_time(prev_sends).should be_nil
      end
      it "works when there is only one weekly message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Week 1 Monday 10:00'];
        subject.reverse_engineer_subscription_time(prev_sends).should == Time.new(2014,1,6,7,5,0)
        Timecop.return
      end
      it "works when there is one weekly and day 1 message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Day 1 20:00','Week 1 Monday 10:00'];
        subject.reverse_engineer_subscription_time(prev_sends).should == Time.new(2014,1,5,19,05,0)
        Timecop.return
      end
      it "works when there is one weekly and 2 days(second day today) message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Day 1 20:00','Day 2 08:00','Week 1 Monday 10:00'];
        subject.reverse_engineer_subscription_time(prev_sends).should == Time.new(2014,1,5,19,5,0)
        Timecop.return
      end
      it "works when there is one weekly and 2 days(second day yesterday) message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Day 1 20:00','Day 2 18:00','Week 1 Monday 10:00'];
        subject.reverse_engineer_subscription_time(prev_sends).should == Time.new(2014,1,4,22,5,0)
        Timecop.return
      end
      it "works when there is one weekly and full week daily message sent before" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
        prev_sends = ['Day 1 20:00','Day 2 18:00','Day 3 10:00', 'Day 4 12:00',
          'Day 5 21:00','Day 6 19:00','Day 7 12:00','Week 1 Monday 10:00'];
        subject.reverse_engineer_subscription_time(prev_sends).should == Time.new(2013,12,30,22,5,0)
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
          subscription.created_at.should == Time.new(2014,1,5,19,5,0)
        Timecop.return
      end
      it "does not alter the subscription time if the subscriber is added for first time" do
        Timecop.freeze(Time.new(2014,1,6,10,5,0)) #Monday
          new_sub = create(:subscriber,user:user)
          channel.subscribers << new_sub
          subscription = Subscription.where(subscriber_id:new_sub.id,channel_id:channel.id).first
          subscription.created_at.should == Time.new(2014,1,6,10,5,0)
        Timecop.return
      end
    end
  end


end
