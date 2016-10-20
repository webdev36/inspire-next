class RemoveTpartyListIdFromChannel < ActiveRecord::Migration
  def up
    remove_column :channels, :tparty_list_id
  end

  def down
    add_column :channels, :tparty_list_id, :string
  end
end
