class AddUserToChatrom < ActiveRecord::Migration
  def change
    add_column :chatrooms, :user_id, :integer
  end
end
