class CreateRuleActivities < ActiveRecord::Migration
  def change
    create_table :rule_activities do |t|
      t.integer :rule_id
      t.integer :subscriber_id
      t.boolean :success
      t.text :message
      t.text :data

      t.timestamps null: false
    end
  end
end
