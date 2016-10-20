# == Schema Information
#
# Table name: messages
#
#  id                           :integer          not null, primary key
#  title                        :text
#  caption                      :text
#  type                         :string(255)
#  channel_id                   :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  content_file_name            :string(255)
#  content_content_type         :string(255)
#  content_file_size            :integer
#  content_updated_at           :datetime
#  seq_no                       :integer
#  next_send_time               :datetime
#  primary                      :boolean
#  reminder_message_text        :text
#  reminder_delay               :integer
#  repeat_reminder_message_text :text
#  repeat_reminder_delay        :integer
#  number_of_repeat_reminders   :integer
#  options                      :text
#  deleted_at                   :datetime
#  schedule                     :text
#

require 'spec_helper'

describe ActionMessage do
  it "has a valid factory" do
    expect(build(:action_message)).to be_valid
  end
  describe "#" do
    let(:user){create(:user)}
    let(:from_channel){create(:channel,user:user)}
    let(:to_channel){create(:channel,user:user)}
    let(:subscriber){create(:subscriber,user:user)}
    let(:switch_channel_action){create(:switch_channel_action)}
    let(:action_message){create(:action_message,channel:from_channel)}
    subject {action_message}
    before do
      action_message.action = switch_channel_action
      action_message.save
      from_channel.subscribers << subscriber
    end

    describe '#type_abbr' do
      subject { super().type_abbr }
      it {is_expected.to eq('Action')}
    end

    describe '#primary' do
      subject { super().primary }
      it {is_expected.to be_truthy}
    end

    describe '#requires_user_response?' do
      subject { super().requires_user_response? }
      it {is_expected.to be_falsey}
    end

    describe '#requires_response' do
      subject { super().requires_response }
      it {is_expected.to be_falsey}
    end

    describe '#internal?' do
      subject { super().internal? }
      it {is_expected.to be_truthy}
    end
    it "send_to_subscribers calls execute on associated action" do
      expect(action_message.action).to receive(:execute){|opts|
        expect(opts[:subscribers]).to match_array([Subscriber.find(subscriber)])
        expect(opts[:channel]).to eq(from_channel)
        expect(opts[:message]).to eq(subject)
      }
      subject.send_to_subscribers([subscriber])
    end
  end

end
