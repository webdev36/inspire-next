class Chatroom < ActiveRecord::Base
  has_many :chatroom_chatters
  belongs_to :user
  has_many :chats

  def add_subscriber(subscriber)
    crc = self.chatroom_chatters.new
    crc.chatter_id = subscriber.id
    crc.chatter_type = 'Subscriber'
    crc.save
    crc
  end

  def subscribers
    self.chatroom_chatters
  end
end
