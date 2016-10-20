class AddReminderMessageTextToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :reminder_message_text, :string
    add_column :messages, :reminder_delay, :integer
    add_column :messages, :repeat_reminder_message_text, :string
    add_column :messages, :repeat_reminder_delay, :integer
    add_column :messages, :number_of_repeat_reminders, :integer
    add_column :messages, :options, :text
  end
end
