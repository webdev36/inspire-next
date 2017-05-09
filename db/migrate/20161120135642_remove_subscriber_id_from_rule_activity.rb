class RemoveSubscriberIdFromRuleActivity < ActiveRecord::Migration
  def change
    remove_column :rule_activities, :subscriber_id
  end
end
