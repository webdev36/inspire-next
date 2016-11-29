class Chat < ActiveRecord::Base
  belongs_to :chatroom
  belongs_to :chatter, polymorphic: true
  validate :membership_in_chatroom, on: :create

  def membership_in_chatroom
    if chatter_type == 'Subscriber'
      errors.add(:chatter, "is not a member of the chatroom") unless
        self.chatter.chatrooms.include?(self.chatroom)
    else
      errors.add(:chatter, 'is not an owner of this chatroom') unless
        self.chatroom.user_id == self.chatter_id
    end
  end
end
