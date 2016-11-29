class Chatroom < ActiveRecord::Base
  has_many :chatroom_chatters
  has_many :subscribers, through: :chatroom_chatters, source: 'subscriber'
  has_many :users
  has_many :chats
end
