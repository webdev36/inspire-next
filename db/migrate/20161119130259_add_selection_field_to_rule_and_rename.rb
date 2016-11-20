class AddSelectionFieldToRuleAndRename < ActiveRecord::Migration
  def change
    rename_column :rules, :if, :rule_if
    rename_column :rules, :then, :rule_then
    add_column :rules, :selection, :text
  end
end
