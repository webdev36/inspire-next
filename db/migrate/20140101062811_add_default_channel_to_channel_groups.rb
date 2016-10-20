class AddDefaultChannelToChannelGroups < ActiveRecord::Migration
  def change
    add_column :channel_groups, :default_channel_id, :integer
  end
end
