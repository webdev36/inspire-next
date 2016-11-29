require 'spec_helper'

describe Mixins::ChatNames do
  context 'users' do
    it 'generated and saved on first use' do
      user = create :user
      expect(user.chatname.blank?).to be_falsey
      find_user = User.find(user.id)
      expect(find_user.chat_name == user.chatname).to be_truthy
    end
    it 'can change their chat name' do
      user = create :user
      chatname = user.chatname
      user.generate_chat_name!
      expect(user.chat_name == chatname).to be_falsey
    end
  end
  context 'subscribers' do
    it 'generated and saved on first use' do
      user = create :subscriber
      expect(user.chatname.blank?).to be_falsey
      find_user = Subscriber.find(user.id)
      expect(find_user.chat_name == user.chatname).to be_truthy
    end
    it 'can change their chat name' do
      user = create :subscriber
      chatname = user.chatname
      user.generate_chat_name!
      expect(user.chat_name == chatname).to be_falsey
    end
  end
end
