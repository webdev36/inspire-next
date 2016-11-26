# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#

require 'spec_helper'

describe SwitchChannelAction do

  it 'has a valid factory' do
    expect(build(:switch_channel_action)).to be_valid
  end

  it 'requires to_channel' do
    expect(build(:switch_channel_action,to_channel:nil)).not_to be_valid
  end

  it 'stores the action in as_text' do
    sc = create(:switch_channel_action,to_channel:"40")
    expect(SwitchChannelAction.find(sc.id).as_text).to eq("Switch channel to 40")
  end

  describe "#" do
    subject {create(:switch_channel_action,to_channel:"40")}

    describe '#get_to_channel_from_text' do
      subject { super().get_to_channel_from_text }
      it {is_expected.to eq("40")}
    end
    describe "virtual attribute" do
      describe "to_channel" do
        it "returns new value if set" do
          subject.to_channel = "33"
          expect(subject.to_channel).to eq("33")
        end
        it "returns parsed value if not previously set" do
          subject.to_channel = nil
          expect(subject.to_channel).to eq("40")
        end
      end
    end
    describe "execute" do
      let(:user) {create(:user)}
      let(:cg){create(:channel_group,user:user)}
      let(:ch1){create(:channel,user:user)}
      let(:ch2){create(:channel,user:user)}
      let(:subs){create(:subscriber,user:user)}
      let(:cmd){create(:switch_channel_action,to_channel:ch2.to_param)}
      before do
        cg.channels << [ch1,ch2]
        ch1.subscribers << subs
      end

      it "moves a subscriber from one channel to another" do
        expect {
          expect(
            cmd.execute( { subscribers:[subs], from_channel:ch1} )
            ).to eq(true)
        }.to change{
          ActionNotice.count
          }.by(2)
        expect(ch1.subscribers).not_to be_include(subs)
        expect(ch2.subscribers).to be_include(subs)
      end

      it "returns false if subscriber or from_channel is blank" do
        expect(cmd.execute({subscribers:[],from_channel:ch1})).to eq(false)
        expect(cmd.execute({subscribers:[subs],from_channel:nil})).to eq(false)
      end

      it "does not error if the subscriber is NOT in the channel on remove" do
        ch1.subscribers.delete(subs)
        expect {
          cmd.execute({subscribers:[subs],from_channel:ch1})
        }.to_not change {
          ActionErrorNotice.count
        }
      end

      it "returns true if subscriber is already in to_channel and removes him from from_channel" do
        ch2.subscribers << subs
        expect(cmd.execute({subscribers:[subs],from_channel:ch1})).to eq(true)
        expect(ch1.subscribers).not_to be_include(subs)
      end
    end
  end
end
