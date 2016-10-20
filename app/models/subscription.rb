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

class Subscription < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :subscriber
  belongs_to :channel

  validates :subscriber_id, uniqueness:{scope:[:channel_id,:deleted_at]}
end
