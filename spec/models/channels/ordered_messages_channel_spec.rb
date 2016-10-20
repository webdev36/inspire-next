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
  describe '#factory works' do
    subject { super().factory works }
    it do
    expect(build(:ordered_messages_channel)).to be_valid
  end
  end
  describe "#" do
    let(:user){create(:user)}
    let(:channel){create(:ordered_messages_channel,user:user)}
    subject { channel }

    describe '#has_schedule?' do
      subject { super().has_schedule? }
      it {is_expected.to be_truthy}
    end

    describe '#sequenced?' do
      subject { super().sequenced? }
      it { is_expected.to be_truthy}
    end

    describe '#broadcastable?' do
      subject { super().broadcastable? }
      it { is_expected.to be_falsey}
    end

    describe '#type_abbr' do
      subject { super().type_abbr }
      it {is_expected.to eq('Ordered')}
    end
    
    describe "perform_post_send_ops" do
      it "updates the seq_no in subscribers" do
        msg = create(:message,channel:channel)
        msg.update_column(:seq_no,rand(100))
        sub1 = create(:subscriber,user:user)
        sub2 = create(:subscriber,user:user)
        h={msg.id=>[sub1,sub2]}
        subject.perform_post_send_ops(h)
        expect(sub1.last_msg_seq_no).to eq(msg.seq_no)
        expect(sub2.last_msg_seq_no).to eq(msg.seq_no)
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
        expect(h[msg1.id]).to match_array([sub1,sub2])
        expect(h[msg2.id]).to eq(nil)
        expect(h[msg3.id]).to match_array([sub3,sub4])
      end
    end    
  end
end
