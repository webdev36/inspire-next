class AddKeywordToChannelGroups < ActiveRecord::Migration
  def change
    add_column :channel_groups, :keyword, :string
  end
end
