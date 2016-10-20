class CreateDeliveryNotices < ActiveRecord::Migration
  def change
    create_table :delivery_notices do |t|
      t.references :subscriber
      t.references :message

      t.timestamps
    end
    add_index :delivery_notices, :subscriber_id
    add_index :delivery_notices, :message_id
  end
end
