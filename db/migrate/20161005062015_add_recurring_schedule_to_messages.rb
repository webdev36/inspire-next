class AddRecurringScheduleToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :recurring_schedule, :text
  end
end
