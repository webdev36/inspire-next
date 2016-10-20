class AddActiveToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :active, :boolean
  end
end
