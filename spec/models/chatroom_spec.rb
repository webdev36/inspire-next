require 'spec_helper'

RSpec.describe Chatroom, type: :model do
  it 'has a factory' do
    @chatroom = create :chatroom
    expect(@chatroom.is_a?(Chatroom)).to be_truthy
  end
  context 'add and remove subscribers' do
    let(:chatroom) { create :chatroom }
    let(:subscriber) { create :subscriber, user: chatroom.user }
    it 'adds and deletes subscribers' do
      chatroom.subscribers << subscriber
      expect(subscriber.chatrooms.length == 1).to be_truthy
    end
    it 'deletes subscribers' do
      chatroom.subscribers << subscriber
      expect(subscriber.chatrooms.length == 1).to be_truthy
      chatroom.subscribers.delete(subscriber)
      subscriber.reload
      expect(subscriber.chatrooms.length == 0).to be_truthy
    end
  end
  context 'chats' do
    let(:chatroom) { create :chatroom }
    let(:subscriber1) { create :subscriber, user: chatroom.user }
    let(:subscriber2) { create :subscriber, user: chatroom.user }
    let(:user) { chatroom.user }
    let(:user2) { create :user }
    it 'adds chats' do
      chatroom.subscribers << subscriber1
      chatroom.subscribers << subscriber2
      chatroom.chats << subscriber1.chats.new(body: 'this is a chat')
      chatroom.chats << subscriber2.chats.new(body: 'this is a chat 2')
      expect(chatroom.chats.length == 2).to be_truthy
      expect(subscriber1.chats.length == 1).to be_truthy
    end
    it 'rejects chats if the subscriber is not subscribed' do
      chat = subscriber1.chats.new(body: 'this is a chat')
      resp = chatroom.chats.push(chat)
      expect(resp).to be_falsey
      expect(chat.errors.messages.keys.include?(:chatter)).to be_truthy
    end
    it 'user can add a chat' do
      chatroom.chats << user.chats.new(body: 'This is a user chat')
    end
    it 'non-owner users cannot add a chat' do
      resp = chatroom.chats << user2.chats.new(body: 'This is a user chat')
      expect(resp).to be_falsey
    end
  end
end
