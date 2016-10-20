# == Schema Information
#
# Table name: channels
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  user_id           :integer
#  type              :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  keyword           :string(255)
#  tparty_keyword    :string(255)
#  next_send_time    :datetime
#  schedule          :text
#  channel_group_id  :integer
#  one_word          :string(255)
#  suffix            :string(255)
#  moderator_emails  :text
#  real_time_update  :boolean
#  deleted_at        :datetime
#  relative_schedule :boolean
#  send_only_once    :boolean          default(FALSE)
#

require 'spec_helper'

describe OrderedMessagesChannel do
  its "factory works" do
    expect(build(:ordered_messages_channel)).to be_valid
  end
  describe "#" do
    let(:user){create(:user)}
    let(:channel){create(:ordered_messages_channel,user:user)}
    subject { channel }
    its(:has_schedule?) {should be_true}
    its(:sequenced?) { should be_true}
    its(:broadcastable?) { should be_false}
    its(:type_abbr){should == 'Ordered'}
    
    describe "perform_post_send_ops" do
      it "updates the seq_no in subscribers" do
        msg = create(:message,channel:channel)
        msg.update_column(:seq_no,rand(100))
        sub1 = create(:subscriber,user:user)
        sub2 = create(:subscriber,user:user)
        h={msg.id=>[sub1,sub2]}
        subject.perform_post_send_ops(h)
        sub1.last_msg_seq_no.should == msg.seq_no
        sub2.last_msg_seq_no.should == msg.seq_no
      end
    end

    describe "group_subscribers_by_message" do
      it "returns subscribers grouped by messages" do
        msg1 = create(:message,channel:channel)
        msg2 = create(:message,channel:channel)
        msg3 = create(:message,channel:channel)
        sub1 = create(:subscriber,user:user,last_msg_seq_no:0)
        sub2 = create(:subscriber,user:user,last_msg_seq_no:nil)
        sub3 = create(:subscriber,user:user,last_msg_seq_no:msg2.seq_no)
        sub4 = create(:subscriber,user:user,last_msg_seq_no:msg2.seq_no)
        sub5 = create(:subscriber,user:user,last_msg_seq_no:msg3.seq_no)
        channel.subscribers = [sub1,sub2,sub3,sub4,sub5]
        h = channel.group_subscribers_by_message
        h[msg1.id].should =~ [sub1,sub2]
        h[msg2.id].should == nil
        h[msg3.id].should =~ [sub3,sub4]
      end
    end    
  end
end
