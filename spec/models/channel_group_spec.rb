# == Schema Information
#
# Table name: channel_groups
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  description        :text
#  user_id            :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  tparty_keyword     :string(255)
#  keyword            :string(255)
#  default_channel_id :integer
#  moderator_emails   :text
#  real_time_update   :boolean
#  deleted_at         :datetime
#

require 'spec_helper'

describe ChannelGroup do
  it "has a valid factory" do
    expect(build(:channel_group)).to be_valid
  end

  it "requires name to be present" do
    expect(build(:channel_group,name:'')).to_not be_valid
  end

  it "requires name to be unique for a user" do
    name = Faker::Lorem.word
    user = create(:user)
    create(:channel_group,name:name,user:user)
    expect(build(:channel_group,name:name,user:user)).to_not be_valid
    expect(build(:channel_group,name:name)).to be_valid
  end

  it "validates keyword is unique for a given tparty_keyword" do
    TpartyKeywordValidator.any_instance.stub(:validate_each){}
    create(:channel_group,keyword:'sample',tparty_keyword:'sample')
    expect(build(:channel_group,keyword:'sample',tparty_keyword:'sample')).to_not be_valid
  end

  it "allows similar keyword across different tparty_keyword" do
    TpartyKeywordValidator.any_instance.stub(:validate_each){}
    create(:channel_group,keyword:'sample',tparty_keyword:'sample1')
    expect(build(:channel_group,keyword:'sample',tparty_keyword:'sample2')).to be_valid
  end

  it "validates tparty_keyword to check if primary or is available" do
    TpartyKeywordValidator.any_instance.should_receive(:validate_each){|record,attribute,value|
      attribute.should == :tparty_keyword
      value.should == 'sample'
    }
    create(:channel_group,keyword:'sample',tparty_keyword:'sample')
  end

  it "validates moderator emails are valid" do
    EmailsValidator.any_instance.should_receive(:validate_each){|record,attribute,value|
      attribute.should == :moderator_emails
      value.should == 'abc@def.com'
    }
    create(:channel_group,moderator_emails:'abc@def.com')
  end

  it "allows moderator_emails to be blank" do
    EmailsValidator.any_instance.should_not_receive(:validate_each){}
    create(:channel_group,moderator_emails:nil)
    create(:channel_group,moderator_emails:'')
  end

  it "upon creation calls MessagingManagerWorker to create keyword if required" do
    TpartyKeywordValidator.any_instance.stub(:validate_each){}
    keyword = Faker::Lorem.word
    MessagingManagerWorker.should_receive(:perform_async){|action,opts|
      action.should == 'add_keyword'
      opts['keyword'].should == keyword
    }
    create(:channel_group,tparty_keyword:keyword)
  end

  it "upon destroy calls MessagingManagerWorker to remove keyword if required" do
    channel_group = create(:channel_group,keyword:Faker::Lorem.word)
    MessagingManagerWorker.should_receive(:perform_async){|action,opts|
      action.should == 'remove_keyword'
      opts['keyword'].should == channel_group.tparty_keyword
    }
    channel_group.destroy
  end

  it "holds multiple channels and allows selection of a single channel as default channel" do
    user = create(:user)
    ch1 = create(:channel,user:user)
    ch2 = create(:channel,user:user)
    channel_group = create(:channel_group,user:user)
    ch1.channel_group = channel_group
    ch2.channel_group = channel_group
    ch1.save
    ch2.save
    ch1 = Channel.find(ch1)
    ch2 = Channel.find(ch2)
    channel_group = ChannelGroup.find(channel_group)
    channel_group.channels.to_a.should =~ [ch1,ch2]
    channel_group.default_channel = ch2
    channel_group.save
    channel_group = ChannelGroup.find(channel_group)
    channel_group.channels.to_a.should =~ [ch1,ch2]
    channel_group.default_channel.should == ch2
  end

  describe "all_channel_subscribers" do
    before do
      @user = create(:user)
      @channel_group = create(:channel_group,user:@user)
      @channel1 = create(:channel,user:@user)
      @channel2 = create(:channel,user:@user)
      @subs1 = create(:subscriber,user:@user)
      @subs2 = create(:subscriber,user:@user)
      @subs3 = create(:subscriber,user:@user)
      @subs4 = create(:subscriber,user:@user)
      @channel_group.channels << [@channel1,@channel2]
      @channel1.subscribers << [@subs1,@subs2]
      @channel2.subscribers << [@subs3]
    end
    it "returns an array of subscribers of all the channels" do
      @channel_group.all_channel_subscribers.should =~ [@subs1,@subs2,@subs3]
    end
  end

  describe "identify_command" do
    it "identifies start command" do
      Channel.identify_command('Start').should == :start
    end

    it "identifies stop command" do
      Channel.identify_command('Stop').should == :stop
    end

    it "identifies custom single word command" do
      Channel.identify_command(Faker::Lorem.word).should == :custom
    end

    it "identifies custom multi word command" do
      Channel.identify_command(Faker::Lorem.sentence).should == :custom
    end
  end

  describe "#" do
    let(:tparty_keyword) {Faker::Lorem.word}
    let(:user) {create(:user)}
    let(:channel_group) {create(:channel_group,user:user,tparty_keyword:tparty_keyword)}
    let(:subject) {channel_group}

    it "holds channels " do
      ch1 = subject.user.channels.create(attributes_for(:channel))
      subject.channels << ch1

      # ch1 = create(:channel,user:user)
      # subject.channels << ch1
      subject.reload.channels.should == [Channel.find(ch1.id)]
    end

    it "holds channels of same user" do
      ch1 = create(:channel,user:user)
      subject.channels << ch1
      ch2 = create(:channel)
      expect {
        subject.channels << ch2
      }.to_not change{subject.channels.count}
    end

    it "does not allow addition of a channel belonging to another group" do
      ch1 = create(:channel,user:user)
      cg2 = create(:channel_group,user:user)
      cg2.channels << ch1
      expect {
        subject.channels << ch1
      }.to_not change{subject.channels.count}
    end

    describe "process_subscriber_response" do
      it "initiate start command processing on receiving start com" do
        sr = create(:subscriber_response,message_content:'start',
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_start_command)
        subject.process_subscriber_response(sr)
      end

      it "initiates stop command processing on receiving stop command" do
        sr = create(:subscriber_response,message_content:'stop',
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_stop_command)
        subject.process_subscriber_response(sr)
      end

      it "initiates custom command processing on receiving custom command" do
        sr = create(:subscriber_response,message_content:'',
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_custom_command)
        subject.process_subscriber_response(sr)
        sr = create(:subscriber_response,caption:Faker::Lorem.sentence,
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_custom_command)
        subject.process_subscriber_response(sr)
      end
    end

    describe "process_start_command" do
      before do
        @ch1 = create(:channel,user:user)
        @ch2 = create(:channel,user:user)
        subject.channels << @ch1
        subject.channels << @ch2
        subject.default_channel = @ch2
        subject.save
        @phone_number = Faker::PhoneNumber.us_phone_number
      end
      it "starts the subscriber on the default channel adding to system if he is not already a subscriber" do
        sr = create(:subscriber_response,tparty_keyword:tparty_keyword,
          message_content:Faker::Lorem.sentence,
          origin:@phone_number)
        expect {subject.process_start_command(sr)}.to change{
          subject.user.subscribers.count
        }.by(1)
        ch1 = Channel.find(@ch1)
        ch2 = Channel.find(@ch2)
        ch1.subscribers.size.should == 0
        ch2.subscribers.size.should == 1
        ch2.subscribers[0].phone_number.should == Subscriber.format_phone_number(@phone_number)

      end
      it "does not add subscriber to system if he is already there (just starts on the default channel)" do
        create(:subscriber,user:user,phone_number:@phone_number)
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:@phone_number)
        expect {subject.process_start_command(sr)}.to_not change{
          subject.user.subscribers.count}
        ch1 = Channel.find(@ch1)
        ch2 = Channel.find(@ch2)
        ch1.subscribers.size.should == 0
        ch2.subscribers.size.should == 1
        ch2.subscribers[0].phone_number.should == Subscriber.format_phone_number(@phone_number)
      end

      it "does nothing if user is already a member of any channel in the group" do
        subs1 = create(:subscriber,user:user,phone_number:@phone_number)
        @ch1.subscribers << subs1
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:@phone_number)
        subject.process_start_command(sr)
        ch1 = Channel.find(@ch1)
        ch2 = Channel.find(@ch2)
        ch1.subscribers.size.should == 1
        ch2.subscribers.size.should == 0
      end

      it "fails if subscriber phone number is invalid" do
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:'')
        subject.process_start_command(sr).should == false
      end

      it "fails if default_channel is not set for the channel group" do
        subject.default_channel = nil
        subject.save
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:@phone_number)
        subject.process_start_command(sr).should == false
      end
    end
    describe "process_stop_command" do
      before do
        @ch1 = create(:channel,user:user)
        @ch2 = create(:channel,user:user)
        subject.channels << @ch1
        subject.channels << @ch2
        @phone_number = Faker::PhoneNumber.us_phone_number
        @subscriber = create(:subscriber,user:user,phone_number:@phone_number)
        @ch1.subscribers << @subscriber
      end
      it "removes subscriber from any channel in the group" do
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:@phone_number)
        @ch1.subscribers.count.should == 1
        subject.process_stop_command(sr).should == true
        ch1 = Channel.find(@ch1)
        ch1.subscribers.count.should == 0
      end
      it "returns false if subscriber is not in any channel" do
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:@phone_number)
        @ch1.subscribers.delete(@subscriber)
        subject.process_stop_command(sr).should == false
      end
    end

    describe "process_custom_command" do
      it "triggers on-demand channel processing first" do
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_on_demand_channels){true}
        subject.should_not_receive(:associate_subscriber_response_with_channel)
        subject.process_custom_command(sr).should == true
      end

      it "if on demand processing fails, finds channel based on subscriber and asks it to process custom command" do
        ch1 = create(:channel,user:user)
        subject.channels << ch1
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,user:user,phone_number:phone_number)
        ch1.subscribers << subscriber
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:phone_number)
        subject.stub(:process_on_demand_channels){false}
        Channel.any_instance.should_receive(:process_custom_command){true}
        subject.process_custom_command(sr).should == true
      end
    end

    describe "associate_subscriber_response_with_channel" do
      it "sets the channel field in the subscriber_response with the channel that has the subscriber" do
        ch1 = create(:channel,user:user)
        ch2 = create(:channel,user:user)
        subject.channels << [ch1,ch2]
        phone_number = Faker::PhoneNumber.us_phone_number
        subs = create(:subscriber,user:user,phone_number:phone_number)
        ch2.subscribers << subs
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,origin:phone_number)
        expect{
          subject.associate_subscriber_response_with_channel(sr)}.to change{
            ch2.subscriber_responses.count
          }.by(1)
        sr = SubscriberResponse.find(sr)
        sr.channel.should == Channel.find(ch2)
      end
    end
    describe "ask_channel_to_process_subscriber_response" do
      it "should let the channel process the subscriber_response" do
        ch = double
        sr = double
        ch.should_receive(:process_custom_command){|psr|
          psr.should == sr
        }
        subject.ask_channel_to_process_subscriber_response(ch,sr)
      end
      it "should return the value returned by the channel" do
        ch = double
        ch.stub(:process_custom_command){true}
        sr = double
        subject.ask_channel_to_process_subscriber_response(ch,sr).should == true
      end
    end
    describe "process_on_demand_channels" do
      let(:one_word) {Faker::Lorem.word}
      let(:phone_number) {Faker::PhoneNumber.us_phone_number}
      let(:tparty_keyword) {Faker::Lorem.word}
      let(:cg) {create(:channel_group,tparty_keyword:tparty_keyword,user:user)}
      let(:subs) {create(:subscriber,user:user)}
      let(:ch1) {create(:on_demand_messages_channel,tparty_keyword:tparty_keyword,
                one_word:one_word,user:user)}
      let(:ch2) {create(:channel,user:user,tparty_keyword:tparty_keyword)}
      before do
        ch2.subscribers << subs
        cg.channels << [ch1,ch2]
      end
      it "calls process_subsriber_response of an on-demand channel if there is a match with one_word" do
        sr = create(:subscriber_response,message_content:one_word,tparty_keyword:tparty_keyword,
          origin:phone_number)
        Channel.any_instance.stub(:process_subscriber_response){|psr|
          psr.should == SubscriberResponse.find(sr)
          true
        }
        ch2.should_not_receive(:process_subscriber_response)
        cg.process_on_demand_channels(sr).should == true
      end
      it "returns false if the message was blank" do
        sr = create(:subscriber_response,tparty_keyword:tparty_keyword,
          origin:phone_number)
        cg.process_on_demand_channels(sr).should == false
      end
      it "returns false if there were no matches among on-demand channels" do
        cg.channels.delete(ch1)
        ch3 = create(:on_demand_messages_channel,tparty_keyword:tparty_keyword,
                one_word:"#{one_word}asd",user:user)
        cg.channels << ch3
        sr = create(:subscriber_response,tparty_keyword:tparty_keyword,message_content:one_word,
          origin:phone_number)
        Channel.any_instance.should_not receive(:process_subscriber_response)
        cg.process_on_demand_channels(sr).should == false
      end
      it "returns false if there are no on-demand channels" do
        cg.channels.delete(ch1)
        sr = create(:subscriber_response,tparty_keyword:tparty_keyword,message_content:one_word,
          origin:phone_number)
        Channel.any_instance.should_not receive(:process_subscriber_response)
        cg.process_on_demand_channels(sr).should == false
      end
    end

  end
end
