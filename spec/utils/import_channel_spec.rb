require 'spec_helper'

describe ImportChannel do
  let(:file)    { File.new("#{Files.fixture_path}utils/import_channel/channel-249-messages-2016-11-16.csv") }
  let(:channel) { create :channel }
  let(:helper)  { ImportChannel.new(channel, file) }

  describe 'creates input objects' do
    it 'for message options' do
      expect(helper.message_options_objects.length > 0).to be_truthy
    end
    it 'for messages' do
      expect(helper.message_objects.length > 0).to be_truthy
    end
  end

  describe 'creates' do
    it 'messages' do
      expect { helper.import }.to change { Message.count }
    end
  end
end
