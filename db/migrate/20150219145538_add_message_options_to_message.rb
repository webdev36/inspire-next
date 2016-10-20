class AddMessageOptionsToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :message_options, :string
  end
end
