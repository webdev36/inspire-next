class AddDataHashToAction < ActiveRecord::Migration
  def change
    add_column :actions, :data, :text
    add_column :subscribers, :data, :text
  end
end
