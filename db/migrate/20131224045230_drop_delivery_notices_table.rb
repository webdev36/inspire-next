class DropDeliveryNoticesTable < ActiveRecord::Migration
  def up
    drop_table :delivery_notices
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
