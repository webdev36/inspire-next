class AddPublicWebSignup < ActiveRecord::Migration
  def change
    add_column :channel_groups, :web_signup, :boolean, :default => false
  end

end
