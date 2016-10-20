class RemoveMogreetReferencesFromModel < ActiveRecord::Migration
  def change
    rename_column :channels, :mogreet_list_id, :tparty_list_id
    rename_column :channels, :mogreet_list_name, :tparty_list_name
    rename_column :channels, :mogreet_keyword, :tparty_keyword
    rename_column :messages, :mogreet_id, :tparty_content_id
  end
end
