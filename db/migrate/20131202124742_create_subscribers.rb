class CreateSubscribers < ActiveRecord::Migration
  def change
    create_table :subscribers do |t|
      t.string :name
      t.string :phone_number
      t.text :remarks
      t.integer :last_msg_seq_no
      t.references :user

      t.timestamps
    end
    add_index :subscribers, :user_id
  end
end
