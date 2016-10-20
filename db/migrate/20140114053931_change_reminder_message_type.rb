class ChangeReminderMessageType < ActiveRecord::Migration
  def up
    change_column :messages,:reminder_message_text,:text
    change_column :messages,:repeat_reminder_message_text,:text
  end

  def down
    change_column :messages,:reminder_message_text,:string
    change_column :messages,:repeat_reminder_message_text,:string    
  end
end
