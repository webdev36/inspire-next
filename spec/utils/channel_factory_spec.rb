require 'spec_helper'

describe ChannelFactory do
  it 'can create a channel from a params hash' do
    params = Files.json_read_from_fixture_path('utils/channel_factory/new_channel_with_recurring_schedule.json')
    factory = ChannelFactory.new(params)
    new_channel = factory.channel
    expect(new_channel.save).to be_truthy
  end
end
