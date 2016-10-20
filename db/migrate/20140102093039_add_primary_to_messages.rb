class AddPrimaryToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :primary, :boolean
  end
end
