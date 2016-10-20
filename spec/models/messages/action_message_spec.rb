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
    its(:type_abbr) {should == 'Action'}
    its(:primary) {should be_true}
    its(:requires_user_response?) {should be_false}
    its(:requires_response){should be_false}
    its(:internal?) {should be_true}
    it "send_to_subscribers calls execute on associated action" do
      action_message.action.should_receive(:execute){|opts|
        opts[:subscribers].should =~ [Subscriber.find(subscriber)]
        opts[:channel].should == from_channel
        opts[:message].should == subject
      }
      subject.send_to_subscribers([subscriber])
    end
  end

end
