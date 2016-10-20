class AddMoSubscriptionDeadlineToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :mo_subscription_deadline, :datetime
  end
end
