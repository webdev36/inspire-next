class AddSendOnlyOnceToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :send_only_once, :boolean, :default=>false
  end
end
