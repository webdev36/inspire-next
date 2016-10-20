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
  describe '#factory works' do
    subject { super().factory works }
    it do
    expect(build(:announcements_channel)).to be_valid
  end
  end
  describe "#" do
    subject { create(:announcements_channel) }

    describe '#has_schedule?' do
      subject { super().has_schedule? }
      it {is_expected.to be_falsey}
    end

    describe '#sequenced?' do
      subject { super().sequenced? }
      it { is_expected.to be_falsey}
    end

    describe '#broadcastable?' do
      subject { super().broadcastable? }
      it { is_expected.to be_truthy}
    end

    describe '#type_abbr' do
      subject { super().type_abbr }
      it {is_expected.to eq('Announcements')}
    end
    it "reset_next_send_time resets next_send_time to 10 years" do
      subject.reset_next_send_time 
      expect(subject.next_send_time).to be > 9.years.from_now
    end
  end
end
