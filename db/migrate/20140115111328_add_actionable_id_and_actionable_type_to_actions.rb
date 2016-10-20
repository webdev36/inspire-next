class AddActionableIdAndActionableTypeToActions < ActiveRecord::Migration
  def change
    add_column :actions, :actionable_id, :integer
    add_column :actions, :actionable_type, :string
  end
end
