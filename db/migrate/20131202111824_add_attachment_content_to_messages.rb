class AddAttachmentContentToMessages < ActiveRecord::Migration
  def self.up
    change_table :messages do |t|
      t.attachment :content
    end
  end

  def self.down
    drop_attached_file :messages, :content
  end
end
