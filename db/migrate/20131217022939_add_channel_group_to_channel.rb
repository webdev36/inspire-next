class AddChannelGroupToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :channel_group_id, :integer
  end
end
