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
    expect(sr.title).to eq('a mixed case string')
    expect(sr.caption).to eq('another mixed case string')
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
      expect(SubscriberResponse.parse_message('')).to eq([nil,nil,nil,''])
    end  
    it "identifies channel with primary tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}  #{@keyword.swapcase}    #{@message}")
      expect(target).to eq(Channel.find(@ch_pri_key))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message)
    end
    it "identifies channel with primary tparty_keyword and keyword when tparty_keyword is outside the message" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@keyword.swapcase}    #{@message}",@tparty_primary.swapcase  )
      expect(target).to eq(Channel.find(@ch_pri_key))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message)
    end    
    it "identifies channel with custom tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      expect(target).to eq(Channel.find(@ch_custom_key))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message)
    end  

    it "identifies channel with custom tparty_keyword and keyword when tparty_keyword is passed in outside message" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@keyword.swapcase} #{@message}",@tparty_custom.swapcase)
      expect(target).to eq(Channel.find(@ch_custom_key))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message)
    end  


    it "identifies channel with only tparty_keyword if there is a single match" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      expect(target).to eq(Channel.find(@ch_pri))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message)
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@message}")
      expect(target).to eq(Channel.find(@ch_custom))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message)        
    end 

    it "identifies channel with only tparty_keyword if there is a single match when message does not contain it" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@message}",@tparty_primary.swapcase)
      expect(target).to eq(Channel.find(@ch_pri))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message)
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@message}",@tparty_custom.swapcase )
      expect(target).to eq(Channel.find(@ch_custom))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message)        
    end      

    it "identifies channel with only tparty_keyword and no message if there is a single match" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}")
      expect(target).to eq(Channel.find(@ch_pri))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase}")
      expect(target).to eq(Channel.find(@ch_custom))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')       
    end  

    it "identifies channel with only tparty_keyword and no message if there is a single match when identifier is not part of message" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "",@tparty_primary.swapcase)
      expect(target).to eq(Channel.find(@ch_pri))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "",@tparty_custom.swapcase)
      expect(target).to eq(Channel.find(@ch_custom))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')       
    end  

    it "does not identify channel if there are multiple matches" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      expect(target).to be_nil
      expect(tparty_keyword).to be_nil
      expect(keyword).to be_nil
      expect(message).to eq("#{@tparty_primary.swapcase} #{@message}")
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
      expect(SubscriberResponse.parse_message('')).to eq([nil,nil,nil,''])
    end  
    
    it "identifies channel group with primary tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}  #{@keyword.swapcase}    #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_pri_key))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message)
    end
    it "identifies channel group with custom tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom_key))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message)
    end  

    it "identifies channel group with only tparty_keyword if there is a single match" do
      @ch_grp_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_pri))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message)
      @ch_grp_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message)        
    end

    it "identifies channel group with only tparty_keyword and no message if there is a single match" do
      @ch_grp_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_pri))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
      @ch_grp_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')       
    end      

    it "does not identify channel group if there are multiple matches" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      expect(target).to be_nil
      expect(tparty_keyword).to be_nil
      expect(keyword).to be_nil
      expect(message).to eq("#{@tparty_primary.swapcase} #{@message}")
    end

    it "returns channel group when both channel and channel group of a given primary tparty keyword are present" do
      ch = create(:channel,tparty_keyword:@tparty_primary,keyword:@keyword)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_primary.swapcase}  #{@keyword.swapcase}    #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_pri_key))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message)       
    end

    it "returns channel group when both channel and channel group of a given custom tparty keyword are present" do
      @ch_grp_custom_key.destroy
      ch = create(:channel,tparty_keyword:@tparty_custom)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_custom.swapcase}  #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message)       
    end 

    it "returns channel group when both channel and channel group of a given custom tparty keyword and keyword are present" do
      ch = create(:channel,tparty_keyword:@tparty_custom,keyword:@keyword)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom_key))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message)       
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
      allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
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
      expect(sr.reload.channel).to eq(Channel.find(channel))
      expect(sr.subscriber).to eq(Subscriber.find(subscriber))
    end

    it "populates channel if subscriber is new or invalid" do
      sr = create(:subscriber_response,caption:"#{tparty_keyword.swapcase} #{true_message}",
        origin:Faker::PhoneNumber.us_phone_number)
      expect(sr.reload.channel).to eq(Channel.find(channel))
    end

    it "returns channel/channelgroup as target" do
      expect(subject.reload.target).to eq(Channel.find(@channel))
    end

    it "identifies the tparty_keyword" do
      expect(subject.tparty_keyword).to eq(tparty_keyword)
    end

    it "identifies keyword if present" do
      expect(subject.keyword).to eq(keyword)
    end

    it "identifies content_text" do
      expect(subject.content_text.casecmp(true_message)).to eq(0)
    end

    describe "process" do
      it "calls process_subscriber_response of the channel/channel_group" do
        expect(subject.channel).to receive(:process_subscriber_response){}
        subject.process
      end
      it "udpates the processed field to true if process_subscriber_response succeeds" do
        allow(subject.channel).to receive(:process_subscriber_response){true}
        subject.process
        expect(subject.processed).to eq(true)
      end
      it "retains the processed field if process_subscriber_response fails" do
        allow(subject.channel).to receive(:process_subscriber_response){false}
        expect {subject.process}.to_not change{subject.processed}
        subject.update_attribute(:processed,true)
        expect {subject.process}.to_not change{subject.processed}
      end

    end
  end

end
