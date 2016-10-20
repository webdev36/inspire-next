class RemoveNameFromCommands < ActiveRecord::Migration
  def up
    remove_column :commands, :name
  end

  def down
    add_column :commands, :name, :string
  end
end
