class AddActiveToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :active, :boolean, default:true
  end
end
