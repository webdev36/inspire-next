class AddEmailToSubscribers < ActiveRecord::Migration
  def change
    add_column :subscribers, :email, :string
  end
end
