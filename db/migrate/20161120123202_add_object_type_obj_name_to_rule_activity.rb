class AddObjectTypeObjNameToRuleActivity < ActiveRecord::Migration
  def change
    add_column :rule_activities, :ruleable_id, :integer
    add_column :rule_activities, :ruleable_type, :string
    add_index :rule_activities, [:ruleable_type, :ruleable_id]
  end
end
