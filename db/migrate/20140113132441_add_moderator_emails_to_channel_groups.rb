class AddModeratorEmailsToChannelGroups < ActiveRecord::Migration
  def change
    add_column :channel_groups, :moderator_emails, :text
  end
end
