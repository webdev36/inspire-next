class AddRelativeScheduleToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :relative_schedule, :boolean
  end
end
