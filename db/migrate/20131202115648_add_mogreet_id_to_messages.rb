class AddMogreetIdToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :mogreet_id, :string
  end
end
