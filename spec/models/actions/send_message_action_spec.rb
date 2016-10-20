require 'spec_helper'

describe SendMessageAction do

  it 'has a valid factory' do
    expect(build(:send_message_action)).to be_valid
  end

  it 'requires message_to_send' do
    build(:send_message_action,message_to_send:nil).should_not be_valid
  end

  it 'stores the action in as_text' do
    sc = create(:send_message_action,message_to_send:"40")
    SendMessageAction.find(sc).as_text.should == "Send message 40"
  end

  describe "#" do
    subject {create(:send_message_action,message_to_send:"40")}
    its(:get_message_to_send_from_text) {should == "40"}
    describe "virtual attribute" do
      describe "message_to_send" do
        it "returns new value if set" do
          subject.message_to_send = "33"
          subject.message_to_send.should == "33"
        end
        it "returns parsed value if not previously set" do
          subject.message_to_send = nil
          subject.message_to_send.should == "40"
        end
      end            
    end
    describe "execute" do
      let(:user) {create(:user)}
      let(:ch1){create(:channel,user:user)}
      let(:msg){create(:message,channel:ch1)}
      let(:subs){create(:subscriber,user:user)}
      let(:cmd){create(:send_message_action,message_to_send:msg.to_param)}
      it "sends the message to subscriber" do
        expect {
          cmd.execute({subscribers:[subs]}).should == true
        }.to change{DeliveryNotice.count}.by(1)
        DeliveryNotice.last.subscriber_id.should == subs.id 
        DeliveryNotice.last.message_id.should == msg.id
      end
      it "returns false if message does not exist" do
        cmd1 = create(:send_message_action,message_to_send:rand(1000000))
        cmd1.execute({subscribers:[subs]}).should == false
      end
    end
  end
 
end
