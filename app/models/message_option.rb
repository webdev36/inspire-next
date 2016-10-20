class MessageOption < ActiveRecord::Base
  attr_accessible :key, :message_id, :value
  belongs_to :message
end
