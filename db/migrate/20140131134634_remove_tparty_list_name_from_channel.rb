class RemoveTpartyListNameFromChannel < ActiveRecord::Migration
  def up
    remove_column :channels, :tparty_list_name
  end

  def down
    add_column :channels, :tparty_list_name, :string
  end
end
