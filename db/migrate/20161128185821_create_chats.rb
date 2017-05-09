class CreateChats < ActiveRecord::Migration
  def change
    create_table :chats do |t|
      t.references :chatroom, index: true, foreign_key: true
      t.references :chatter, polymorphic: true, index: true
      t.text :body

      t.timestamps null: false
    end
  end
end
