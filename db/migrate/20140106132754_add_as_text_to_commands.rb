class AddAsTextToCommands < ActiveRecord::Migration
  def change
    add_column :commands, :as_text, :text
  end
end
