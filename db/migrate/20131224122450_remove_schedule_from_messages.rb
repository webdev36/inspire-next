class RemoveScheduleFromMessages < ActiveRecord::Migration
  def up
    remove_column :messages, :schedule
  end

  def down
    add_column :messages, :schedule, :text
  end
end
