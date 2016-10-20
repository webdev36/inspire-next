class AddScheduleToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :schedule, :text
  end
end
