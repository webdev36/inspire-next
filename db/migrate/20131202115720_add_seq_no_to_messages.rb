class AddSeqNoToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :seq_no, :integer
  end
end
