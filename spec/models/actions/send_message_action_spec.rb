require 'spec_helper'

describe SendMessageAction do

  it 'has a valid factory' do
    expect(build(:send_message_action)).to be_valid
  end

  it 'requires message_to_send' do
    expect(build(:send_message_action,message_to_send:nil)).not_to be_valid
  end

  it 'stores the action in as_text' do
    sc = create(:send_message_action,message_to_send:"40")
    expect(SendMessageAction.find(sc.id).as_text).to eq("Send message 40")
  end

  describe "#" do
    let(:subject) { create(:send_message_action,message_to_send:"40") }
    it 'has correct subject text' do
      expect(subject.get_message_to_send_from_text == '40').to be_truthy
    end
    describe "virtual attribute" do
      describe "message_to_send" do
        it "returns new value if set" do
          subject.message_to_send = "33"
          expect(subject.message_to_send).to eq("33")
        end
        it "returns parsed value if not previously set" do
          subject.message_to_send = nil
          expect(subject.message_to_send).to eq("40")
        end
      end
    end
    describe "execute" do
      let(:user) { create(:user) }
      let(:ch1)  { create(:channel,user:user) }
      let(:msg)  { create(:message,channel:ch1) }
      let(:subs) { create(:subscriber,user:user) }
      let(:cmd)  { create(:send_message_action,message_to_send:msg.to_param) }
      it "sends the message to subscriber" do
        expect {
          expect(cmd.execute({subscribers:[subs]})).to eq(true)
        }.to change{DeliveryNotice.count}.by(1)
        expect(DeliveryNotice.last.subscriber_id).to eq(subs.id)
        expect(DeliveryNotice.last.message_id).to eq(msg.id)
      end
      it "returns false if message does not exist" do
        cmd1 = create(:send_message_action,message_to_send:rand(1000000))
        expect(cmd1.execute({subscribers:[subs]})).to eq(false)
      end
    end
  end

end
