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

describe SubscriberActivity do
  it "has a valid factory" do
    expect(build(:subscriber_activity)).to be_valid
  end

  it "of_subscriber gives only those belonging to the subscriber" do
    subs1 = create(:subscriber)
    dn1 = create(:delivery_notice,subscriber:subs1)
    dn2 = create(:delivery_notice)
    dn3 = create(:delivery_notice,subscriber:subs1)
    SubscriberActivity.of_subscriber(subs1).should =~ [dn1,dn3]
  end

  it "of_subscribers gives only those belonging to the subscribers" do
    subs1 = create(:subscriber)
    subs2 = create(:subscriber)
    subs3 = create(:subscriber)
    dn1 = create(:delivery_notice,subscriber:subs1)
    dn2 = create(:delivery_notice)
    dn3 = create(:delivery_notice,subscriber:subs1)
    dn4 = create(:delivery_notice,subscriber:subs2)
    dn5 = create(:delivery_notice,subscriber:subs3)
    SubscriberActivity.of_subscribers([subs1,subs2]).should =~ [dn1,dn3,dn4]
  end

  it "for_message gives only those about the message" do
    message = create(:message)
    dn1 = create(:delivery_notice,message:message)
    dn2 = create(:delivery_notice)
    dn3 = create(:delivery_notice,message:message)
    SubscriberActivity.for_message(message).should =~ [dn1,dn3]
  end

  it "for_messages gives only those about the messages" do
    message1 = create(:message)
    message2 = create(:message)
    message3 = create(:message)
    dn1 = create(:delivery_notice,message:message1)
    dn2 = create(:delivery_notice)
    dn3 = create(:delivery_notice,message:message2)
    dn4 = create(:delivery_notice,message:message3)
    SubscriberActivity.for_messages([message1,message2]).should =~ [dn1,dn3]
  end

  it "for_channel gives only those about the channel" do
    channel = create(:channel)
    message1 = create(:message,channel:channel)
    message2 = create(:message)
    dn1 = create(:delivery_notice,message:message1)
    dn2 = create(:delivery_notice,message:message2)
    dn3 = create(:delivery_notice,message:message1)
    SubscriberActivity.for_channel(channel).should =~ [dn1,dn3]
  end

  it "for_channels gives only those about the channels" do
    user = create(:user)
    channel1 = create(:channel,user:user)
    channel2 = create(:channel,user:user)
    message1 = create(:message,channel:channel1)
    message2 = create(:message,channel:channel2)
    message3 = create(:message)
    dn1 = create(:delivery_notice,message:message1)
    dn2 = create(:delivery_notice,message:message2)
    dn3 = create(:delivery_notice,message:message3)
    SubscriberActivity.for_channels([channel1,channel2]).should =~ [dn1,dn2]
  end 

  it "for_channel_group gives only those about the channel_group" do
    channel_group = create(:channel_group)
    sr1 = create(:subscriber_response,channel_group:channel_group)
    sr2 = create(:subscriber_response)
    sr3 = create(:subscriber_response,channel_group:channel_group)
    SubscriberActivity.for_channel_group(channel_group).should =~ [sr1,sr3]
  end

  it "for_channel_groups gives only those about the channel_groups" do
    user = create(:user)
    channel_group1 = create(:channel_group,user:user)
    channel_group2 = create(:channel_group,user:user)
    channel_group3 = create(:channel_group,user:user)
    sr1 = create(:subscriber_response,channel_group:channel_group1)
    sr2 = create(:subscriber_response,channel_group:channel_group3)
    sr3 = create(:subscriber_response,channel_group:channel_group2)
    SubscriberActivity.for_channel_groups([channel_group1,channel_group2]).should =~ [sr1,sr3]
  end    

  it "unprocessed gives only those that are unprocessed" do
    sr1 = create(:subscriber_response)
    sr2 = create(:subscriber_response)
    sr3 = create(:subscriber_response)
    sr1.processed=true
    sr2.processed=true
    sr1.save
    sr2.save
    SubscriberActivity.unprocessed.should == [sr3]
  end

  describe "#" do
    let(:user){create(:user)}
    let(:channel){create(:channel,user:user)}
    let(:channel_group){create(:channel_group,user:user)}
    let(:subscriber){create(:subscriber,user:user)}
    let(:message){create(:message,channel:channel)}
    before do
      channel.subscribers << subscriber
    end
    subject {create(:delivery_notice,message:message,subscriber:subscriber)}
    it "populates the channel field using the message" do
      subject.channel.should == Channel.find(channel)
    end
    describe "parent_type" do
      it "returns right value for message responses" do
        subject.parent_type.should == :message
      end
      it "returns right value for responses from subscribers not related to message" do
        sr = create(:subscriber_response,subscriber:subscriber,channel:channel)
        sr.parent_type.should == :subscriber
      end
      it "returns right value for responses to a channel(start etc)" do
        sr = create(:subscriber_response,channel:channel,subscriber:nil)
        sr.parent_type.should == :channel
      end
      it "returns right value for responses to a channel_group(start etc)" do
        sr = create(:subscriber_response,channel_group:channel_group,subscriber:nil)
        sr.parent_type.should == :channel_group
      end
    end
  end  

end
