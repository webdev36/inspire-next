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

describe RandomMessagesChannel do
  its "factory works" do
    expect(build(:random_messages_channel)).to be_valid
  end
  describe "#" do
    let(:user) {create(:user)}
    let(:channel) {create(:random_messages_channel,user:user)}
    subject { channel }
    its(:has_schedule?) {should be_true}
    its(:sequenced?) { should be_false}
    its(:broadcastable?) { should be_false}
    its(:type_abbr){should == 'Random'}

    it "group_subscribers_by_message groups all subscribers into message bins" do
      subscribers = (0..4).map{
        subscriber = create(:subscriber,user:user)
        channel.subscribers << subscriber
        subscriber
      }
      messages = (0..6).map{
        create(:message,channel:channel)
      }
      subs=[]
      msh = subject.group_subscribers_by_message
      msh.each {|k,v|
        v.each do |sub|
          subs << sub.id
        end
        v.length.should_not == 5 #Chances of all of them getting same message during random is small
      }
      subs.uniq.length.should == 5 #All subscribers should be involved
    end

    it "send_scheduled_messages sends messages to all subscribers randomly" do
      subscribers = (0..2).map{
        subscriber = create(:subscriber,user:user)
        channel.subscribers << subscriber
        subscriber
      }
      messages = (0..3).map{
        create(:message,channel:channel)
      }
      (0..3).each do
        subject.send_scheduled_messages
      end
      DeliveryNotice.of_subscribers(subscribers).count.should == 12
      DeliveryNotice.for_messages(messages).count.should == 12
      DeliveryNotice.of_subscriber(subscribers[0]).uniq.count.should == 4
    end
  end
end
