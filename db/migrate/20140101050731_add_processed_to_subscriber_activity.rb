class AddProcessedToSubscriberActivity < ActiveRecord::Migration
  def change
    add_column :subscriber_activities, :processed, :boolean
  end
end
