class AddRequiresResponseToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :requires_response, :boolean
  end
end
