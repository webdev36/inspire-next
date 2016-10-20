# == Schema Information
#
# Table name: subscriptions
#
#  id            :integer          not null, primary key
#  channel_id    :integer
#  subscriber_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  deleted_at    :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscription do
    channel
    subscriber
  end
end
