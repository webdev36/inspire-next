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

describe DeliveryNotice do
  it "has a valid factory" do
    expect(build(:delivery_notice)).to be_valid
  end

  it "of_primary_messages filters delivery notice of only primary messages" do
    subs = create(:subscriber)
    m1 = create(:message,primary:true)
    m2 = create(:message,primary:false)
    m3 = create(:message,primary:true)
    dn1 = create(:delivery_notice,subscriber:subs,message:m1)
    dn2 = create(:delivery_notice,subscriber:subs,message:m2)
    dn3 = create(:delivery_notice,subscriber:subs,message:m3)
    expect(DeliveryNotice.of_primary_messages.to_a).to match_array([dn1,dn3])
  end

  it "of_primary_messages_that_require_response filters delivery notice of only primary messages" do
    subs = create(:subscriber)
    m1 = create(:response_message,primary:true)
    m2 = create(:response_message,primary:false)
    m3 = create(:poll_message,primary:true)
    m4 = create(:simple_message,primary:true)
    dn1 = create(:delivery_notice,subscriber:subs,message:m1)
    dn2 = create(:delivery_notice,subscriber:subs,message:m2)
    dn3 = create(:delivery_notice,subscriber:subs,message:m3)
    dn4 = create(:delivery_notice,subscriber:subs,message:m4)
    expect(DeliveryNotice.of_primary_messages_that_require_response.to_a).to match_array([dn1,dn3])
  end



  describe "#" do
    let(:user){create(:user)}
    let(:channel){create(:channel,user:user)}
    let(:subscriber){create(:subscriber,user:user)}
    let(:message){create(:message,channel:channel)}
    before do
      channel.subscribers << subscriber
    end
    subject {create(:delivery_notice,message:message,subscriber:subscriber)}
    it "populates the channel field using the message" do
      expect(subject.channel).to eq(Channel.find(channel.id))
    end
    it "always sets the processed field to true" do
      expect(subject.processed).to eq(true)
    end
  end
end
