class AddOptionsToSubscriberActivity < ActiveRecord::Migration
  def change
    add_column :subscriber_activities, :options, :text
  end
end
