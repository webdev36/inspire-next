class AddDeletedAtToModels < ActiveRecord::Migration
  def change
    add_column :channels, :deleted_at, :datetime
    add_column :channel_groups, :deleted_at, :datetime
    add_column :subscribers, :deleted_at, :datetime
    add_column :messages, :deleted_at, :datetime
    add_column :subscriber_activities, :deleted_at, :datetime
    add_column :subscriptions, :deleted_at, :datetime
    add_column :actions, :deleted_at, :datetime
  end
end
