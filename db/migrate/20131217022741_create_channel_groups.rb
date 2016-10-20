class CreateChannelGroups < ActiveRecord::Migration
  def change
    create_table :channel_groups do |t|
      t.string :name
      t.text :description
      t.references :user

      t.timestamps
    end
    add_index :channel_groups, :user_id
  end
end
