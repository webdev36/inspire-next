class AddSuffixToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :suffix, :string
  end
end
