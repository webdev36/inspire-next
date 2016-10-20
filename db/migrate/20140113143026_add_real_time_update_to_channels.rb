class AddRealTimeUpdateToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :real_time_update, :boolean
  end
end
