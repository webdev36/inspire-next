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

require 'spec_helper'

describe Subscription do
  # it "has a working factory" do
  #   build(:subscription).should be_valid
  # end
end
