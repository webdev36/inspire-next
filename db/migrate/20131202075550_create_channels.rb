class CreateChannels < ActiveRecord::Migration
  def change
    create_table :channels do |t|
      t.string :name
      t.text :description
      t.references :user
      t.string :type

      t.timestamps
    end
    add_index :channels, :user_id
  end
end
