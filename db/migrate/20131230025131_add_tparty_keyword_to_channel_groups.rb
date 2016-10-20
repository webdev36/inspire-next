class AddTpartyKeywordToChannelGroups < ActiveRecord::Migration
  def change
    add_column :channel_groups, :tparty_keyword, :string
  end
end
