# == Schema Information
#
# Table name: messages
#
#  id                           :integer          not null, primary key
#  title                        :text
#  caption                      :text
#  type                         :string(255)
#  channel_id                   :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  content_file_name            :string(255)
#  content_content_type         :string(255)
#  content_file_size            :integer
#  content_updated_at           :datetime
#  seq_no                       :integer
#  next_send_time               :datetime
#  primary                      :boolean
#  reminder_message_text        :text
#  reminder_delay               :integer
#  repeat_reminder_message_text :text
#  repeat_reminder_delay        :integer
#  number_of_repeat_reminders   :integer
#  options                      :text
#  deleted_at                   :datetime
#  schedule                     :text
#

require 'spec_helper'

describe Message do

  it "has a valid factory" do
    expect(build(:message)).to be_valid
  end

  it "creates a default sequence number equal to the size of current messages" do
    channel = create(:channel)
    message = create(:message,channel:channel)
    message.seq_no.should == 1
    message = create(:message,channel:channel)
    message.seq_no.should == 2
    message = create(:message,channel:channel)
    message.seq_no.should == 3
    message = create(:message)
    message.seq_no.should == 1
  end

  it "does not allow sequence numbers to be the same in a channel" do
    channel = create(:channel)
    message = create(:message,channel:channel)
    expect(build(:message,channel:channel,seq_no:message.seq_no)).to_not be_valid
  end

  it "does allow sequence numbers to be the same across channels" do
    channel = create(:channel)
    message = create(:message,channel:channel)
    expect(build(:message,seq_no:message.seq_no)).to be_valid
  end

  it "sets the model_name of any subclass as Message to enable STI use single controller" do
    SimpleMessage.model_name.should == Message.model_name
    ActionMessage.model_name.should == Message.model_name
  end  

  it "pending_send returns messages whose next_send_time is in the past" do
      message1 = create(:simple_message,next_send_time:1.day.ago)
      message2 = create(:simple_message,next_send_time:1.minute.ago)
      message3 = create(:simple_message,next_send_time:1.hour.from_now)
      message4 = create(:simple_message,next_send_time:1.day.from_now)
      Message.pending_send.should =~ [message1,message2]
  end

  it "primary scope returns primary messages(e.g. not reminder etc)" do
    message1 = create(:message)
    message2 = create(:message)
    message1.primary = false
    message1.save
    Message.primary.to_a.should == [Message.find(message2)]
  end

  it "secondary scope returns non-primary messages(e.g. not reminder etc)" do
    message1 = create(:message)
    message2 = create(:message)
    message2.primary = false
    message2.save
    Message.secondary.to_a.should == [Message.find(message2)]
  end  
  
  describe "#" do
    let(:user) {create(:user)}
    let(:channel) {create(:channel,user:user)}
    let(:message) {create(:poll_message,channel:channel)}
    let(:subscriber) {create(:subscriber,user:user)}
    let(:subscriber2) {create(:subscriber,user:user)}
    subject {message}
    before do 
      channel.subscribers << subscriber
      channel.subscribers << subscriber2
    end

    it "options stores options as a hash" do
      message.options[:channel_id]=10
      message.options[:subscriber_id]=20
      retval = message.save
      msg = Message.find(message.id)
      msg.options[:channel_id].should == 10
      msg.options[:subscriber_id].should == 20
    end
    
    it "delivery_notices lists the delivery notices" do
      dn1 = create(:delivery_notice,message:message,subscriber:subscriber)
      dn2 = create(:delivery_notice,message:message,subscriber:subscriber)
      subject.delivery_notices.to_a.should =~ [dn1,dn2]
    end
    
    it "subscriber_responses lists the subscriber responses" do
      sr1 = create(:subscriber_response, message:message, subscriber:subscriber)
      sr2 = create(:subscriber_response, message:message, subscriber:subscriber)
      subject.subscriber_responses.to_a.should =~ [sr1,sr2]
    end

    describe "move_up" do
      let(:message1) {create(:message,channel:channel)}
      let(:message2) {create(:message,channel:channel)}
      it "swaps the seq_no of this and earlier message" do
        prev_seq1 = message1.seq_no
        prev_seq2 = message2.seq_no
        message2.move_up 
        message1.reload.seq_no.should == prev_seq2
        message2.reload.seq_no.should == prev_seq1
      end
      it "does nothing when the message is the first message for this channel" do
        message = create(:message)
        seq_no = message.seq_no
        message.move_up
        message.seq_no.should == seq_no
      end
    end
    describe "move_down" do
      let(:message1) {create(:message,channel:channel)}
      let(:message2) {create(:message,channel:channel)}
      it "swaps the seq_no of this and later message" do
        prev_seq1 = message1.seq_no
        prev_seq2 = message2.seq_no
        message1.move_down 
        message1.reload.seq_no.should == prev_seq2
        message2.reload.seq_no.should == prev_seq1
      end
      it "does nothing when the message is the last message for this channel" do
        message = create(:message)
        seq_no = message.seq_no
        message.move_down
        message.seq_no.should == seq_no
      end
    end
    describe "broadcast" do
      before do
        @channel = create(:channel)
        @message = create(:message,channel:@channel)
      end
      subject {@message}
      it "uses a background worker to broadcast" do
        MessagingManagerWorker.should_receive(:perform_async){|action,opts|
          action.should == 'broadcast_message'
          opts['message_id'].should == @message.id
        }
        @message.broadcast
      end
    end

    describe "perform_post_send_ops" do
      it "creates a system secondary messages channel if one does not exist" do
        expect{subject.perform_post_send_ops(nil)}.to change{
          SecondaryMessagesChannel.count}.by(1) 
      end
      it "does not create system secondary messages channel if one exists" do
        SecondaryMessagesChannel.create!(name:"_system_smc",tparty_keyword:"_system_smc")
        expect{subject.perform_post_send_ops(nil)}.to_not change{
          SecondaryMessagesChannel.count}
      end
      it "calls specialized_post_send_ops for subclass specialization" do
        subject.should_receive(:specialized_post_send_ops){|subs|
          subs.should =~ [subscriber,subscriber2]
        }
        subject.perform_post_send_ops([subscriber,subscriber2])
      end  
      it "creates a message in the system secondary channel if reminder message required" do
        message.reminder_message_text = Faker::Lorem.sentence
        message.reminder_delay = 10
        message.save
        smc = SecondaryMessagesChannel.create!(name:"_system_smc",tparty_keyword:"_system_smc")
        expect{subject.perform_post_send_ops([subscriber,subscriber2])}.to change{
          smc.messages.count
        }.by(1)
        smc.messages.last.options[:subscriber_ids].should =~ [subscriber,subscriber2].map(&:id)
        smc.messages.last.options[:message_id].should == message.id
        smc.messages.last.options[:channel_id].should == channel.id
        smc.messages.last.next_send_time.should > 8.minutes.from_now
        smc.messages.last.next_send_time.should < 12.minutes.from_now
      end
      
      it "creates messages in the system secondary channel for repeat reminders" do
        message.repeat_reminder_message_text = Faker::Lorem.sentence
        message.repeat_reminder_delay = 20
        message.number_of_repeat_reminders = 2
        message.save
        smc = SecondaryMessagesChannel.create!(name:"_system_smc",tparty_keyword:"_system_smc")
        expect{subject.perform_post_send_ops([subscriber,subscriber2])}.to change{
          smc.messages.count
        }.by(2)
        smc.messages.last.next_send_time.should > 38.minutes.from_now
        smc.messages.last.next_send_time.should < 42.minutes.from_now         
      end      
    end
  end
  describe "##" do
    let(:message) {build(:message)}
    it "subclasses override all abstract methods" do
      [:action_message,:poll_message,:response_message,
        :simple_message].each  do |child_class|
        msg = build(child_class)
        expect{msg.type_abbr}.to_not raise_error
      end
    end
    it "schedule is built if necessary before validation" do
      message.relative_schedule_type = 'Week'
      message.relative_schedule_number = 1
      message.relative_schedule_day = 'Sunday'
      message.relative_schedule_hour = '18'
      message.relative_schedule_minute = '45'
      message.should be_valid
      message.schedule.should == 'Week 1 Sunday 18:45'
    end
    it "schedule is validated when present" do
      message.relative_schedule_type = 'Week'
      message.relative_schedule_number = 1
      message.relative_schedule_day = 'Sunday'
      message.relative_schedule_hour = '18'
      message.relative_schedule_minute = '70'
      message.should_not be_valid
      message.errors[:relative_schedule_minute].should_not be_nil
    end
    it "nil schedule is valid" do
      message.schedule=nil
      message.should be_valid
    end

  end
end
