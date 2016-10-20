class AddNextSendTimeToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :next_send_time, :datetime
  end
end
