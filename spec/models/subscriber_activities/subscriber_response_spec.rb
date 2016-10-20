# == Schema Information
#
# Table name: subscriber_activities
#
#  id               :integer          not null, primary key
#  subscriber_id    :integer
#  channel_id       :integer
#  message_id       :integer
#  type             :string(255)
#  origin           :string(255)
#  title            :text
#  caption          :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  channel_group_id :integer
#  processed        :boolean
#  deleted_at       :datetime
#

require 'spec_helper'

describe SubscriberResponse do
  it "has a valid factory" do
    expect(build(:subscriber_response)).to be_valid
  end

  it "downcases the message before save" do
    sr = create(:subscriber_response,title:'A mixed Case STRING',caption:"Another Mixed Case STRING")
    sr.reload
    sr.title.should == 'a mixed case string'
    sr.caption.should == 'another mixed case string'
  end

  describe 'parse_message' do
    before do
      @tparty_primary = ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"
      @tparty_custom = Faker::Lorem.word
      @keyword = Faker::Lorem.word
      @message = Faker::Lorem.sentence

      @ch_pri = create(:channel,tparty_keyword:@tparty_primary)
      @ch_pri_key = create(:channel,tparty_keyword:@tparty_primary,
        keyword:@keyword)
      @ch_custom = create(:channel,tparty_keyword:@tparty_custom)
      @ch_custom_key = create(:channel,tparty_keyword:@tparty_custom,
        keyword:@keyword)
    end
    it "returns nil when message is empty" do
      SubscriberResponse.parse_message('').should == [nil,nil,nil,'']
    end  
    it "identifies channel with primary tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}  #{@keyword.swapcase}    #{@message}")
      target.should == Channel.find(@ch_pri_key)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should =~ /^#{@keyword}$/i
      message.should == @message
    end
    it "identifies channel with primary tparty_keyword and keyword when tparty_keyword is outside the message" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@keyword.swapcase}    #{@message}",@tparty_primary.swapcase  )
      target.should == Channel.find(@ch_pri_key)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should =~ /^#{@keyword}$/i
      message.should == @message
    end    
    it "identifies channel with custom tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      target.should == Channel.find(@ch_custom_key)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should =~ /^#{@keyword}$/i
      message.should == @message
    end  

    it "identifies channel with custom tparty_keyword and keyword when tparty_keyword is passed in outside message" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@keyword.swapcase} #{@message}",@tparty_custom.swapcase)
      target.should == Channel.find(@ch_custom_key)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should =~ /^#{@keyword}$/i
      message.should == @message
    end  


    it "identifies channel with only tparty_keyword if there is a single match" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      target.should == Channel.find(@ch_pri)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should be_nil
      message.should == @message
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@message}")
      target.should == Channel.find(@ch_custom)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should be_nil
      message.should == @message        
    end 

    it "identifies channel with only tparty_keyword if there is a single match when message does not contain it" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@message}",@tparty_primary.swapcase)
      target.should == Channel.find(@ch_pri)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should be_nil
      message.should == @message
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@message}",@tparty_custom.swapcase )
      target.should == Channel.find(@ch_custom)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should be_nil
      message.should == @message        
    end      

    it "identifies channel with only tparty_keyword and no message if there is a single match" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}")
      target.should == Channel.find(@ch_pri)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should be_nil
      message.should == ''
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase}")
      target.should == Channel.find(@ch_custom)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should be_nil
      message.should == ''       
    end  

    it "identifies channel with only tparty_keyword and no message if there is a single match when identifier is not part of message" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "",@tparty_primary.swapcase)
      target.should == Channel.find(@ch_pri)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should be_nil
      message.should == ''
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "",@tparty_custom.swapcase)
      target.should == Channel.find(@ch_custom)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should be_nil
      message.should == ''       
    end  

    it "does not identify channel if there are multiple matches" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      target.should be_nil
      tparty_keyword.should be_nil
      keyword.should be_nil
      message.should == "#{@tparty_primary.swapcase} #{@message}"
    end
  end

  describe 'parse_message' do
    before do
      @tparty_primary = ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"
      @tparty_custom = Faker::Lorem.word
      @keyword = Faker::Lorem.word
      @message = Faker::Lorem.sentence

      @ch_grp_pri = create(:channel_group,tparty_keyword:@tparty_primary)
      @ch_grp_pri_key = create(:channel_group,tparty_keyword:@tparty_primary,
        keyword:@keyword)
      @ch_grp_custom = create(:channel_group,tparty_keyword:@tparty_custom)
      @ch_grp_custom_key = create(:channel_group,tparty_keyword:@tparty_custom,
        keyword:@keyword)
    end
    
    it "returns nil when message is empty" do
      SubscriberResponse.parse_message('').should == [nil,nil,nil,'']
    end  
    
    it "identifies channel group with primary tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}  #{@keyword.swapcase}    #{@message}")
      target.should == ChannelGroup.find(@ch_grp_pri_key)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should =~ /^#{@keyword}$/i
      message.should == @message
    end
    it "identifies channel group with custom tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      target.should == ChannelGroup.find(@ch_grp_custom_key)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should =~ /^#{@keyword}$/i
      message.should == @message
    end  

    it "identifies channel group with only tparty_keyword if there is a single match" do
      @ch_grp_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      target.should == ChannelGroup.find(@ch_grp_pri)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should be_nil
      message.should == @message
      @ch_grp_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@message}")
      target.should == ChannelGroup.find(@ch_grp_custom)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should be_nil
      message.should == @message        
    end

    it "identifies channel group with only tparty_keyword and no message if there is a single match" do
      @ch_grp_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}")
      target.should == ChannelGroup.find(@ch_grp_pri)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should be_nil
      message.should == ''
      @ch_grp_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase}")
      target.should == ChannelGroup.find(@ch_grp_custom)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should be_nil
      message.should == ''       
    end      

    it "does not identify channel group if there are multiple matches" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      target.should be_nil
      tparty_keyword.should be_nil
      keyword.should be_nil
      message.should == "#{@tparty_primary.swapcase} #{@message}"
    end

    it "returns channel group when both channel and channel group of a given primary tparty keyword are present" do
      ch = create(:channel,tparty_keyword:@tparty_primary,keyword:@keyword)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_primary.swapcase}  #{@keyword.swapcase}    #{@message}")
      target.should == ChannelGroup.find(@ch_grp_pri_key)
      tparty_keyword.should =~ /^#{@tparty_primary}$/i
      keyword.should =~ /^#{@keyword}$/i
      message.should == @message       
    end

    it "returns channel group when both channel and channel group of a given custom tparty keyword are present" do
      @ch_grp_custom_key.destroy
      ch = create(:channel,tparty_keyword:@tparty_custom)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_custom.swapcase}  #{@message}")
      target.should == ChannelGroup.find(@ch_grp_custom)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should be_nil
      message.should == @message       
    end 

    it "returns channel group when both channel and channel group of a given custom tparty keyword and keyword are present" do
      ch = create(:channel,tparty_keyword:@tparty_custom,keyword:@keyword)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      target.should == ChannelGroup.find(@ch_grp_custom_key)
      tparty_keyword.should =~ /^#{@tparty_custom}$/i
      keyword.should =~ /^#{@keyword}$/i
      message.should == @message       
    end            
  end    

  describe "#" do
    let(:tparty_keyword){Faker::Lorem.word}
    let(:keyword){Faker::Lorem.word}
    let(:true_message){Faker::Lorem.sentence}
    let(:phone_number){Faker::PhoneNumber.us_phone_number}
    let(:user){create(:user)}
    let(:subscriber){create(:subscriber,phone_number:phone_number,user:user)}
    before do
      TpartyKeywordValidator.any_instance.stub(:validate_each){}
      @channel = create(:channel,tparty_keyword:tparty_keyword,keyword:keyword,user:user)
      channel.subscribers << subscriber
      @subscriber_response = create(:subscriber_response,
            caption:"#{tparty_keyword} #{keyword} #{true_message}",
            origin: subscriber.phone_number)
    end
    let(:channel){@channel}
    subject {@subscriber_response}

    it "populates subscriber and channel upon creation" do
      sr = create(:subscriber_response,caption:"#{tparty_keyword.swapcase} #{true_message}",
        origin:phone_number)
      sr.reload.channel.should == Channel.find(channel)
      sr.subscriber.should == Subscriber.find(subscriber)
    end

    it "populates channel if subscriber is new or invalid" do
      sr = create(:subscriber_response,caption:"#{tparty_keyword.swapcase} #{true_message}",
        origin:Faker::PhoneNumber.us_phone_number)
      sr.reload.channel.should == Channel.find(channel)
    end

    it "returns channel/channelgroup as target" do
      subject.reload.target.should == Channel.find(@channel)
    end

    it "identifies the tparty_keyword" do
      subject.tparty_keyword.should == tparty_keyword
    end

    it "identifies keyword if present" do
      subject.keyword.should == keyword
    end

    it "identifies content_text" do
      subject.content_text.casecmp(true_message).should == 0
    end

    describe "process" do
      it "calls process_subscriber_response of the channel/channel_group" do
        subject.channel.should receive(:process_subscriber_response){}
        subject.process
      end
      it "udpates the processed field to true if process_subscriber_response succeeds" do
        subject.channel.stub(:process_subscriber_response){true}
        subject.process
        subject.processed.should == true
      end
      it "retains the processed field if process_subscriber_response fails" do
        subject.channel.stub(:process_subscriber_response){false}
        expect {subject.process}.to_not change{subject.processed}
        subject.update_attribute(:processed,true)
        expect {subject.process}.to_not change{subject.processed}
      end

    end
  end

end
