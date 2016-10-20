require 'spec_helper'

describe ChannelsHelper do
  describe 'channel_types' do
    it 'returns channel types' do
      channel_types.should be_include(:AnnouncementsChannel)
      channel_types.should be_include(:OnDemandMessagesChannel)
      channel_types.should be_include(:ScheduledMessagesChannel)
      channel_types.should be_include(:OrderedMessagesChannel)
      channel_types.should be_include(:RandomMessagesChannel)
      channel_types.should be_include(:IndividuallyScheduledMessagesChannel)
    end
  end
  describe 'user_channel_types' do
    it 'returns user channel types' do
      user_channel_types.should be_include(:AnnouncementsChannel)
      user_channel_types.should be_include(:OnDemandMessagesChannel)
      user_channel_types.should be_include(:ScheduledMessagesChannel)
      user_channel_types.should be_include(:OrderedMessagesChannel)
      user_channel_types.should be_include(:RandomMessagesChannel)
      user_channel_types.should be_include(:IndividuallyScheduledMessagesChannel)
    end
  end  
  describe "channel schedulable" do
    it "returns right values for the various channel types" do
      channel_schedulable?("AnnouncementsChannel").should == false
      channel_schedulable?("OnDemandMessagesChannel").should == false
      channel_schedulable?("ScheduledMessagesChannel").should == true
      channel_schedulable?("OrderedMessagesChannel").should == true
      channel_schedulable?("RandomMessagesChannel").should == true
      channel_schedulable?("UnknownChannelType").should == false
    end
  end
end