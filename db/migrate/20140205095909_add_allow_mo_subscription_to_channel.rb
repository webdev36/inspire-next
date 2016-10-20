class AddAllowMoSubscriptionToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :allow_mo_subscription, :boolean, default:true
  end
end
