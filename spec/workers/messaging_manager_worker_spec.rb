require 'spec_helper'

describe MessagingManagerWorker do
  subject {MessagingManagerWorker}

  describe "add_keyword" do
    it "calls MessagingManager#add_keyword" do
      mw = double.as_null_object
      my_keyword = Faker::Lorem.word
      allow(MessagingManager).to receive(:new_instance){mw}
      expect(mw).to receive(:add_keyword){|kw|
        expect(kw).to eq(my_keyword)
      }
      subject.add_keyword(my_keyword)
    end
  end

  describe "remove_keyword" do
    it "calls MessagingManager#remove_keyword" do
      mw = double.as_null_object
      my_keyword = Faker::Lorem.word
      allow(MessagingManager).to receive(:new_instance){mw}
      allow(mw).to receive(:list_keywords){[my_keyword]}
      expect(mw).to receive(:remove_keyword){|kw|
        expect(kw).to eq(my_keyword)
      }
      subject.remove_keyword(my_keyword)
    end
  end

  describe "broadcast_message" do
    it "calls MessagingManager#broadcast_message" do
      user = create(:user)
      channel = create(:channel,user:user)
      message = create(:message,channel:channel)
      subs1 = create(:subscriber,user:user)
      subs2 = create(:subscriber,user:user)
      channel.subscribers << subs1
      channel.subscribers << subs2
      mw = double.as_null_object
      allow(MessagingManager).to receive(:new_instance){mw}
      expect(mw).to receive(:broadcast_message){|msg,subs|
        expect(msg).to eq(Message.find(message.id))
        expect(subs.to_a).to match_array([subs1,subs2])
      }
      subject.broadcast_message(message.id)
    end
  end

  describe "instance" do
    subject {MessagingManagerWorker.new}
    describe "perform" do
      it "calls add_keyword class method when action is add" do
        keyword = Faker::Lorem.word
        expect(subject.class).to receive(:add_keyword).with(keyword){}
        subject.perform('add_keyword',{'keyword'=>keyword})
      end
      it "calls remove_keyword class method when action is remove" do
        keyword = Faker::Lorem.word
        expect(subject.class).to receive(:remove_keyword).with(keyword){}
        subject.perform('remove_keyword',{'keyword'=>keyword})
      end
      it "calls broadcast_message class method when action is broadcast" do
        message_id = 100
        expect(subject.class).to receive(:broadcast_message){|msg_id|
          expect(msg_id).to eq(message_id)
        }
        subject.perform('broadcast_message',{'message_id'=>message_id})
      end
    end
  end
end
