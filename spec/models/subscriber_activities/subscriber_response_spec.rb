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
  context 'setup' do
    it "has a valid factory" do
      expect(build(:subscriber_response)).to be_valid
    end

    it "downcases the message before save" do
      sr = create(:subscriber_response,title:'A mixed Case STRING',caption:"Another Mixed Case STRING")
      sr.reload
      expect(sr.title).to eq('a mixed case string')
      expect(sr.caption).to eq('another mixed case string')
    end
  end

  context '#channel_keyword_match' do
    it 'can match a message when it has a space' do
      allow(SubscriberResponse).to receive(:potential_matching_keywords).and_return(["slip", "crave", "quit2", "notready", "motivate", "quit", "prepare", "prepare2"])
      test_cases = [
                     { message: ["+14012141426", "not", "ready"],                               channel_keyword: 'notready', array_length: 2 },
                     { message: ["+14012141426", "notready", "i", 'am', 'tired', 'of', 'this'], channel_keyword: 'notready', array_length: 7 },
                     { message: [nil, 'subscribe', 'me'],                                       channel_keyword: nil,        array_length: 3 },
                     { message: ["+14012141426", 'craveit', 'me'],                              channel_keyword: 'crave',    array_length: 4 },
                     { message: ["+14012141426", 'yes'],                                        channel_keyword: nil,        array_length: 2 },
                   ]
      test_cases.each do |tc|
        response = SubscriberResponse.channel_keyword_match(tc[:message])
        expect(response[0] == tc[:channel_keyword]).to be_truthy
        expect(response[1].length == tc[:array_length]).to be_truthy
        puts "#{response}"
      end
    end
  end

  context '#parse_message' do
    before do
      @tparty_primary = ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"
      @tparty_custom = Faker::Lorem.word
      @keyword = Faker::Lorem.word
      @message = Faker::Lorem.sentence

      @ch_pri = create(:channel,tparty_keyword:@tparty_primary)
      @ch_pri_key = create(:channel, tparty_keyword:@tparty_primary,
        keyword:@keyword)
      @ch_custom = create(:channel, tparty_keyword:@tparty_custom)
      @ch_custom_key = create(:channel, tparty_keyword:@tparty_custom,
        keyword:@keyword)
    end
    it "returns nil when message is empty" do
      expect(SubscriberResponse.parse_message('')).to eq([nil,nil,nil,''])
    end

    it "identifies channel with primary tparty_keyword and keyword" do
      message_to_send = "#{@tparty_primary.swapcase}  #{@keyword.swapcase}    #{@message}"
      target, tparty_keyword, keyword, message = SubscriberResponse.parse_message(message_to_send)
      potential_matching_keywords = SubscriberResponse.potential_matching_keywords(tparty_keyword)
      expect(target).to eq(Channel.find(@ch_pri_key.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "identifies channel with primary tparty_keyword and keyword when tparty_keyword is outside the message" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@keyword.swapcase}    #{@message}",@tparty_primary.swapcase  )
      expect(target).to eq(Channel.find(@ch_pri_key.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "identifies channel with custom tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      expect(target).to eq(Channel.find(@ch_custom_key.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "identifies channel with custom tparty_keyword and keyword when tparty_keyword is passed in outside message" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@keyword.swapcase} #{@message}",@tparty_custom.swapcase)
      expect(target).to eq(Channel.find(@ch_custom_key.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "identifies channel with only tparty_keyword if there is a single match" do
      @ch_pri_key.destroy
      message_to_parse = "#{@tparty_primary.swapcase} #{@message}"
      target, tparty_keyword, keyword, message = SubscriberResponse.parse_message(message_to_parse)
      potential_matching_keywords = SubscriberResponse.potential_matching_keywords(tparty_keyword)
      expect(target).to eq(Channel.find(@ch_pri.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message.downcase.split.join(' '))
      @ch_custom_key.destroy
      next_message_to_parse = "#{@tparty_custom.swapcase} #{@message}"
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(next_message_to_parse)
      expect(target).to eq(Channel.find(@ch_custom.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "identifies channel with only tparty_keyword if there is a single match when message does not contain it" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@message}",@tparty_primary.swapcase)
      expect(target).to eq(Channel.find(@ch_pri.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message.downcase.split.join(' '))
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@message}",@tparty_custom.swapcase )
      expect(target).to eq(Channel.find(@ch_custom.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "identifies channel with only tparty_keyword and no message if there is a single match" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}")
      expect(target).to eq(Channel.find(@ch_pri.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase}")
      expect(target).to eq(Channel.find(@ch_custom.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
    end

    it "identifies channel with only tparty_keyword and no message if there is a single match when identifier is not part of message" do
      @ch_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "",@tparty_primary.swapcase)
      expect(target).to eq(Channel.find(@ch_pri.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
      @ch_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "",@tparty_custom.swapcase)
      expect(target).to eq(Channel.find(@ch_custom.id ))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
    end

    it "does not identify channel if there are multiple matches" do
      msg_to_parse = "#{@tparty_primary.swapcase} #{@message}"
      target, tparty_keyword, keyword, message = SubscriberResponse.parse_message(msg_to_parse)
      expect(target).to be_nil
      expect(tparty_keyword).to be_nil
      expect(keyword).to be_nil
      expect(message).to eq(msg_to_parse.downcase)
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
      expect(target).to eq(ChannelGroup.find(@ch_grp_pri_key.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message.downcase.split.join(' '))
    end
    it "identifies channel group with custom tparty_keyword and keyword" do
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom_key.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "identifies channel group with only tparty_keyword if there is a single match" do
      @ch_grp_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase} #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_pri.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message.downcase.split.join(' '))
      @ch_grp_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase} #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "identifies channel group with only tparty_keyword and no message if there is a single match" do
      @ch_grp_pri_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_primary.swapcase}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_pri.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
      @ch_grp_custom_key.destroy
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
        "#{@tparty_custom.swapcase}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq('')
    end

    it "does not identify channel group if there are multiple matches" do
      msg_to_parse = "#{@tparty_primary.swapcase} #{@message}"
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(msg_to_parse)
      expect(target).to be_nil
      expect(tparty_keyword).to be_nil
      expect(keyword).to be_nil
      expect(message).to eq(msg_to_parse.downcase)
    end

    it "returns channel group when both channel and channel group of a given primary tparty keyword are present" do
      ch = create(:channel,tparty_keyword:@tparty_primary,keyword:@keyword)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_primary.swapcase}  #{@keyword.swapcase}    #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_pri_key.id))
      expect(tparty_keyword).to match(/^#{@tparty_primary}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "returns channel group when both channel and channel group of a given custom tparty keyword are present" do
      @ch_grp_custom_key.destroy
      ch = create(:channel,tparty_keyword:@tparty_custom)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_custom.swapcase}  #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to be_nil
      expect(message).to eq(@message.downcase.split.join(' '))
    end

    it "returns channel group when both channel and channel group of a given custom tparty keyword and keyword are present" do
      ch = create(:channel,tparty_keyword:@tparty_custom,keyword:@keyword)
      target,tparty_keyword,keyword,message = SubscriberResponse.parse_message(
       "#{@tparty_custom.swapcase} #{@keyword.swapcase} #{@message}")
      expect(target).to eq(ChannelGroup.find(@ch_grp_custom_key.id))
      expect(tparty_keyword).to match(/^#{@tparty_custom}$/i)
      expect(keyword).to match(/^#{@keyword}$/i)
      expect(message).to eq(@message.downcase.split.join(' '))
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
      expect(sr.reload.channel).to eq(Channel.find(channel.id))
      expect(sr.subscriber).to eq(Subscriber.find(subscriber.id))
    end

    it "populates channel if subscriber is new or invalid" do
      sr = create(:subscriber_response,caption:"#{tparty_keyword.swapcase} #{true_message}",
        origin:Faker::PhoneNumber.us_phone_number)
      expect(sr.reload.channel).to eq(Channel.find(channel.id))
    end

    it "returns channel/channelgroup as target" do
      expect(subject.reload.target).to eq(Channel.find(@channel.id))
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
