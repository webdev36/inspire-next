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
    its(:type_abbr) {should == 'Poll'}
    its(:primary) {should be_true}
    its(:requires_user_response?){should be_true}
    it "should have right value in requires_response in the db" do 
      Message.find(poll_message.id).requires_response.should be_true
    end
  end

end
