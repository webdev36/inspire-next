class AddAdditionalAttributesToSubscriber < ActiveRecord::Migration
  def change
    add_column :subscribers, :additional_attributes, :text
  end
end
