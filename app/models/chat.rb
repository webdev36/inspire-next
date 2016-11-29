class Chat < ActiveRecord::Base
  belongs_to :chatroom
  belongs_to :chatter, polymorphic: true
end
