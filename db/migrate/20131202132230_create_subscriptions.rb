class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :channel_id
      t.integer :subscriber_id

      t.timestamps
    end
  end
end
