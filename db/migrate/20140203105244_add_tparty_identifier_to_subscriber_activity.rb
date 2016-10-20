class AddTpartyIdentifierToSubscriberActivity < ActiveRecord::Migration
  def change
    add_column :subscriber_activities, :tparty_identifier, :string
  end
end
