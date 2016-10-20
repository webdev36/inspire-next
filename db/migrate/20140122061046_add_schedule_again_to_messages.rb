class AddScheduleAgainToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :schedule, :text
  end
end
