class AddChannelGroupToSubscriberActivities < ActiveRecord::Migration
  def change
    add_column :subscriber_activities, :channel_group_id, :integer
  end
end
