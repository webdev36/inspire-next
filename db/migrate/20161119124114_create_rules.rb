class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.string :name
      t.text :description
      t.integer :priority
      t.integer :user_id
      t.text :if
      t.text :then
      t.datetime :next_run_at
      t.boolean :system, default: false
      t.boolean :active, default: false
      t.timestamps null: false
    end
    add_index :rules, [:user_id, :name]
  end
end
