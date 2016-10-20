class AddOneWordToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :one_word, :string
  end
end
