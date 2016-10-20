class AddModeratorEmailsToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :moderator_emails, :text
  end
end
