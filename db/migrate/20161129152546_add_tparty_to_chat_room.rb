class AddTpartyToChatRoom < ActiveRecord::Migration
  def change
    add_column :chatrooms, :tparty_keyword, :string
  end
end
