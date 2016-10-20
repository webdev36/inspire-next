class CreateSubscriberActivities < ActiveRecord::Migration
  def change
    create_table :subscriber_activities do |t|
      t.references :subscriber
      t.references :channel
      t.references :message
      t.string :type
      t.string :origin
      t.text :title
      t.text :caption

      t.timestamps
    end
    add_index :subscriber_activities, :subscriber_id
    add_index :subscriber_activities, :channel_id
    add_index :subscriber_activities, :message_id
  end
end
