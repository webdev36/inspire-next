class RemoveMessageOptionsOnMessage < ActiveRecord::Migration
  def change
    remove_column :messages, :message_options
  end

end
