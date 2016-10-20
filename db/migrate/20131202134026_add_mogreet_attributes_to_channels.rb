class AddMogreetAttributesToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :mogreet_list_id, :string
    add_column :channels, :mogreet_list_name, :string
    add_column :channels, :keyword, :string
    add_column :channels, :mogreet_keyword, :string    
  end
end
