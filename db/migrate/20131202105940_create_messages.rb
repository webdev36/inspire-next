class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.text :title
      t.text :caption
      t.string :type
      t.references :channel

      t.timestamps
    end
    add_index :messages, :channel_id
  end
end
