require 'spec_helper'

describe ChannelsHelper do
  describe 'channel_types' do
    it 'returns channel types' do
      expect(channel_types).to be_include(:AnnouncementsChannel)
      expect(channel_types).to be_include(:OnDemandMessagesChannel)
      expect(channel_types).to be_include(:ScheduledMessagesChannel)
      expect(channel_types).to be_include(:OrderedMessagesChannel)
      expect(channel_types).to be_include(:RandomMessagesChannel)
      expect(channel_types).to be_include(:IndividuallyScheduledMessagesChannel)
    end
  end
  describe 'user_channel_types' do
    it 'returns user channel types' do
      expect(user_channel_types).to be_include(:AnnouncementsChannel)
      expect(user_channel_types).to be_include(:OnDemandMessagesChannel)
      expect(user_channel_types).to be_include(:ScheduledMessagesChannel)
      expect(user_channel_types).to be_include(:OrderedMessagesChannel)
      expect(user_channel_types).to be_include(:RandomMessagesChannel)
      expect(user_channel_types).to be_include(:IndividuallyScheduledMessagesChannel)
    end
  end
  describe "channel schedulable" do
    it "returns right values for the various channel types" do
      expect(channel_schedulable?("AnnouncementsChannel")).to eq(false)
      expect(channel_schedulable?("OnDemandMessagesChannel")).to eq(false)
      expect(channel_schedulable?("ScheduledMessagesChannel")).to eq(true)
      expect(channel_schedulable?("OrderedMessagesChannel")).to eq(true)
      expect(channel_schedulable?("RandomMessagesChannel")).to eq(true)
      expect(channel_schedulable?('IndividuallyScheduledMessagesChannel')).to eq(false)
      expect(channel_schedulable?("UnknownChannelType")).to eq(false)
    end
  end
end
