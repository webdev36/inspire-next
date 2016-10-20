# == Schema Information
#
# Table name: subscriber_activities
#
#  id               :integer          not null, primary key
#  subscriber_id    :integer
#  channel_id       :integer
#  message_id       :integer
#  type             :string(255)
#  origin           :string(255)
#  title            :text
#  caption          :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  channel_group_id :integer
#  processed        :boolean
#  deleted_at       :datetime
#

require 'spec_helper'

describe ActionNotice do
  it "has a valid factory" do
    expect(build(:action_notice)).to be_valid
  end

  # describe "#" do
  #   let(:user){create(:user)}
  #   let(:channel){create(:channel,user:user)}
  #   let(:subscriber){create(:subscriber,user:user)}
  #   let(:message){create(:message,channel:channel)}
  #   before do
  #     channel.subscribers << subscriber
  #   end
  #   subject {create(:delivery_notice,message:message,subscriber:subscriber)}

  #   it "always sets the processed field to true" do
  #     subject.processed.should == true
  #   end
  # end
end
