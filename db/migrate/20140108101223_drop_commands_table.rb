class DropCommandsTable < ActiveRecord::Migration
  def up
    drop_table :commands
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
