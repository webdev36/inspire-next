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

describe AnnouncementsChannel do
  its "factory works" do
    expect(build(:announcements_channel)).to be_valid
  end
  describe "#" do
    subject { create(:announcements_channel) }
    its(:has_schedule?) {should be_false}
    its(:sequenced?) { should be_false}
    its(:broadcastable?) { should be_true}
    its(:type_abbr){should == 'Announcements'}
    it "reset_next_send_time resets next_send_time to 10 years" do
      subject.reset_next_send_time 
      subject.next_send_time.should > 9.years.from_now
    end
  end
end
