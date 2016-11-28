class AddGeneratedNameToSubscriberAndUser < ActiveRecord::Migration
  def change
    add_column :subscribers, :chat_name, :string
    add_column :users, :chat_name, :string
  end
end
