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
    build(:switch_channel_action,to_channel:nil).should_not be_valid
  end

  it 'stores the action in as_text' do
    sc = create(:switch_channel_action,to_channel:"40")
    SwitchChannelAction.find(sc).as_text.should == "Switch channel to 40"
  end

  describe "#" do
    subject {create(:switch_channel_action,to_channel:"40")}
    its(:get_to_channel_from_text) {should == "40"}
    describe "virtual attribute" do
      describe "to_channel" do
        it "returns new value if set" do
          subject.to_channel = "33"
          subject.to_channel.should == "33"
        end
        it "returns parsed value if not previously set" do
          subject.to_channel = nil
          subject.to_channel.should == "40"
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
          cmd.execute({subscribers:[subs],from_channel:ch1}).should == true
        }.to change{ActionNotice.count}.by(1)
        ch1.subscribers.should_not be_include(subs)
        ch2.subscribers.should be_include(subs)
      end
      it "returns false if subscriber or from_channel is blank" do
        cmd.execute({subscribers:[],from_channel:ch1}).should == false
        cmd.execute({subscribers:[subs],from_channel:nil}).should == false
      end
      it "returns false if subscriber is not in from_channel" do
        ch1.subscribers.delete(subs)
        cmd.execute({subscribers:[subs],from_channel:ch1}).should == false
      end
      it "returns true if subscriber is already in to_channel and removes him from from_channel" do
        ch2.subscribers << subs
        cmd.execute({subscribers:[subs],from_channel:ch1}).should == true
        ch1.subscribers.should_not be_include(subs)
      end


    end
  end
 
end
