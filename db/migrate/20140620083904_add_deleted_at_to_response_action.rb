class AddDeletedAtToResponseAction < ActiveRecord::Migration
  def change
    add_column :response_actions, :deleted_at, :datetime
  end
end
