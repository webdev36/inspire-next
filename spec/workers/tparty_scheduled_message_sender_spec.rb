require 'spec_helper'

describe TpartyScheduledMessageSender do
  subject {TpartyScheduledMessageSender}
  describe "send_scheduled_messages" do
    before do
      Timecop.freeze(2.days.ago) do
        user = create(:user)
        @channel1 = create(:random_messages_channel,user:user, schedule:IceCube::Rule.daily)
        @channel2 = create(:random_messages_channel,user:user, schedule:IceCube::Rule.daily)
        @message1 = create(:message, channel:@channel1)
        @message2 = create(:message, channel:@channel2)
        @subs1 = create(:subscriber, user:user,last_msg_seq_no:nil)
        @subs2 = create(:subscriber, user:user,last_msg_seq_no:0)
        @channel1.subscribers << @subs1
        @channel2.subscribers << @subs2
      end
    end

    describe "channels_pending_send" do
      it "returns channels which are pending send" do
        expect(subject.channels_pending_send.to_a).to match_array([@channel1,@channel2])
      end
      it "returns channels only if it is active" do
        @channel1.active=false
        @channel1.save!
        expect(subject.channels_pending_send.to_a).to match_array([@channel2])
      end
    end

    it "calls scheduled_send for the channels" do
      allow(subject).to receive(:channels_pending_send){[@channel1,@channel2]}
      expect(@channel1).to receive(:send_scheduled_messages){}
      expect(@channel2).to receive(:send_scheduled_messages){}
      subject.send_scheduled_messages
    end
  end

  describe "instance" do
    subject {TpartyScheduledMessageSender.new}
    it "perform calls send_scheduled_messages class method" do
      expect(subject.class).to receive(:send_scheduled_messages){}
      subject.perform
    end
  end
end