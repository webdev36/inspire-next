class CreateChatroomChatters < ActiveRecord::Migration
  def change
    create_table :chatroom_chatters do |t|
      t.references :chatroom, index: true, foreign_key: true
      t.references :chatter, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
