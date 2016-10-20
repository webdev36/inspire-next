class CreateMessageOptions < ActiveRecord::Migration
  def change
    create_table :message_options do |t|
      t.integer :message_id
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end
