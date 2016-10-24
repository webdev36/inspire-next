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

describe PollMessage do
  it "has a valid factory" do
    expect(build(:poll_message)).to be_valid
  end
  describe "#" do
    let(:poll_message){create(:poll_message)}
    subject {poll_message}

    describe '#type_abbr' do
      subject { super().type_abbr }
      it {is_expected.to eq('Poll')}
    end

    describe '#primary' do
      subject { super().primary }
      it {is_expected.to be_truthy}
    end

    describe '#requires_user_response?' do
      subject { super().requires_user_response? }
      it {is_expected.to be_truthy}
    end
    it "should have right value in requires_response in the db" do 
      expect(Message.find(poll_message.id).requires_response).to be_truthy
    end
  end

end
