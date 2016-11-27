class AddUserIdToActionNotice < ActiveRecord::Migration
  def change
    add_column :subscriber_activities, :user_id, :integer
  end
end
