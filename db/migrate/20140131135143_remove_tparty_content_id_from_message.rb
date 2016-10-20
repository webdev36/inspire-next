class RemoveTpartyContentIdFromMessage < ActiveRecord::Migration
  def up
    remove_column :messages, :tparty_content_id
  end

  def down
    add_column :messages, :tparty_content_id, :string
  end
end
