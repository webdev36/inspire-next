class Chatroom < ActiveRecord::Base
  belongs_to :user
  has_many :chatroom_chatters, dependent: :destroy
  has_many :chats,             dependent: :destroy
  has_many :subscribers, through: :chatroom_chatters, source: :chatter, source_type: 'Subscriber'

end
