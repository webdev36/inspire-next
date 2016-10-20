class AddMessageIdToResponseAction < ActiveRecord::Migration
  def change
    add_column :response_actions, :message_id, :integer
  end
end
