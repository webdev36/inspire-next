class AddRealTimeUpdateToChannelGroups < ActiveRecord::Migration
  def change
    add_column :channel_groups, :real_time_update, :boolean
  end
end
