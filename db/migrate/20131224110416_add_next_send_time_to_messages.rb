class AddNextSendTimeToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :next_send_time, :datetime
  end
end
