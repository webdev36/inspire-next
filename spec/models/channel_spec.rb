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

describe Channel do
  it "has a valid factory" do
    expect(build(:channel)).to be_valid
  end

  it "requires a name" do
    expect(build(:channel,name:'')).to_not be_valid
  end

  it "requires a unique name for this user" do
    channel = create(:channel)
    expect(build(:channel,name:channel.name,user:channel.user)).to_not be_valid
  end

  it "does not require unique name across users" do
    channel = create(:channel)
    another_user = create(:user)
    expect(build(:channel,name:channel.name,user:another_user)).to be_valid
  end

  it "requires a type" do
    expect(build(:channel,type:'')).to_not be_valid
  end

  it "accepts valid types of Announcement,Scheduled,Ordered,OnDemand and Random" do
    expect(build(:channel,type:'AnnouncementsChannel')).to be_valid
    expect(build(:channel,type:'ScheduledMessagesChannel')).to be_valid
    expect(build(:channel,type:'OrderedMessagesChannel')).to be_valid
    expect(build(:channel,type:'OnDemandMessagesChannel')).to be_valid
    expect(build(:channel,type:'RandomMessagesChannel')).to be_valid
    expect(build(:channel,type:'UnknownMessagesChannel')).to_not be_valid
  end

  it "validates keyword is unique for a given tparty_keyword" do
    TpartyKeywordValidator.any_instance.stub(:validate_each){}
    create(:channel,keyword:'sample',tparty_keyword:'sample')
    expect(build(:channel,keyword:'sample',tparty_keyword:'sample')).to_not be_valid
  end

  it "allows similar keyword across different tparty_keyword" do
    TpartyKeywordValidator.any_instance.stub(:validate_each){}
    create(:channel,keyword:'sample',tparty_keyword:'sample1')
    expect(build(:channel,keyword:'sample',tparty_keyword:'sample2')).to be_valid
  end

  it "validates tparty_keyword to check if primary or is available" do
    TpartyKeywordValidator.any_instance.should_receive(:validate_each){|record,attribute,value|
      attribute.should == :tparty_keyword
      value.should == 'sample'
    }
    create(:channel,keyword:'sample',tparty_keyword:'sample')
  end

  it "validates one_word to ensure it is only a single word" do
    OneWordValidator.any_instance.should_receive(:validate_each){|record,attribute,value|
      attribute.should == :one_word
      value.should == 'sample'
    }
    create(:channel,one_word:'sample')
  end

  it "validates moderator emails are valid" do
    EmailsValidator.any_instance.should_receive(:validate_each){|record,attribute,value|
      attribute.should == :moderator_emails
      value.should == 'abc@def.com'
    }
    create(:channel,moderator_emails:'abc@def.com')
  end

  it "allows moderator_emails to be blank" do
    EmailsValidator.any_instance.should_not_receive(:validate_each){}
    create(:channel,moderator_emails:nil)
    create(:channel,moderator_emails:'')
  end

  it "does not allow similar one_word within same channel group" do
    user=create(:user)
    cg = create(:channel_group,user:user)
    ch1 = create(:channel,user:user)
    ch2 = create(:channel,user:user)
    cg.channels << [ch1,ch2]
    ch1.one_word = 'sample'
    ch1.save
    ch2.one_word = 'sample'
    ch2.should_not be_valid
  end

  it "does allow similar one_word across channel groups" do
    user=create(:user)
    cg1 = create(:channel_group,user:user)
    cg2 = create(:channel_group,user:user)
    ch1 = create(:channel,user:user)
    ch2 = create(:channel,user:user)
    cg1.channels << ch1
    cg2.channels << ch2
    ch1.one_word = 'sample'
    ch1.save
    ch2.one_word = 'sample'
    ch2.should be_valid
  end

  it "upon creation calls MessagingManagerWorker to create keyword if required" do
      TpartyKeywordValidator.any_instance.stub(:validate_each){}
      keyword = Faker::Lorem.word
      MessagingManagerWorker.should_receive(:perform_async){|action,opts|
        action.should == 'add_keyword'
        opts['keyword'].should == keyword
      }
      create(:channel,tparty_keyword:keyword)
  end

  it "upon destroy calls MessagingManagerWorker to remove keyword if required" do
    channel = create(:channel)
    MessagingManagerWorker.should_receive(:perform_async){|action,opts|
      action.should == 'remove_keyword'
      opts['keyword'].should == channel.tparty_keyword
    }
    channel.destroy
  end

  it "ensures the same subscriber is not added more than once" do
    user = create(:user)
    channel = create(:channel,user:user)
    subscriber = create(:subscriber,user:user)
    channel.subscribers << subscriber
    channel.subscribers.count.should == 1
    expect{channel.subscribers << subscriber}.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "ensures the same subscriber is not added if already subscribed to a sibling channel in the group" do
    user = create(:user)
    channel_group = create(:channel_group,user:user)
    channel1 = create(:channel,user:user)
    channel2 = create(:channel,user:user)
    channel_group.channels << channel1
    channel_group.channels << channel2
    subscriber = create(:subscriber,user:user)
    channel1.subscribers << subscriber
    expect {channel2.subscribers << subscriber}.to_not change{
      channel2.subscribers.count}
  end

  it "sets the model_name of any subclass as channel to enable STI use single controller" do
    AnnouncementsChannel.model_name.should == Channel.model_name
  end

  it "keeps track of its child classes" do
    Channel.child_classes =~ [AnnouncementsChannel,ScheduledMessagesChannel,
          OrderedMessagesChannel,RandomMessagesChannel,OnDemandMessagesChannel]
  end

  it "pending send scope returns those channels whose next_send_time is in past" do
    prev_time = 2.days.ago.beginning_of_day
    Timecop.freeze(prev_time)
    channel1 = create(:random_messages_channel,schedule:IceCube::Rule.daily)
    channel2 = create(:random_messages_channel,schedule:IceCube::Rule.weekly.day((prev_time+1.day).strftime("%A").downcase.to_sym))
    channel4 = create(:random_messages_channel,schedule:IceCube::Rule.weekly.day((prev_time+3.days).strftime("%A").downcase.to_sym))
    Timecop.return
    Channel.pending_send.should =~ [channel1,channel2]
  end

  describe "get_next_seq_no" do
    it "returns first seq no if current is nil or 0" do
      Channel.get_next_seq_no(nil,[1,2,3]).should == 1
      Channel.get_next_seq_no(0,[1,2,3]).should == 1
    end
    it "returns correct seq no" do
      Channel.get_next_seq_no(3,[1,2,3,5]).should == 5
    end
    it "returns nil if there are no larger seq_no" do
      Channel.get_next_seq_no(5,[1,2,3,5]).should == nil
    end

  end

  describe "find_by_keyword" do
    it "is case insensitive" do
      channel = create(:channel,keyword:'SampleKeyword')
      channel = Channel.find(channel.id)
      Channel.find_by_keyword(channel.keyword.upcase).should == channel
      Channel.find_by_keyword(channel.keyword.downcase).should == channel
      Channel.find_by_keyword(channel.keyword.swapcase).should == channel
    end
  end

  describe "by_keyword" do
    it "is case insensitive" do
      channel = create(:channel,keyword:'SampleKeyword')
      channel = Channel.find(channel.id)
      Channel.by_keyword(channel.keyword.upcase).first.should == channel
      Channel.by_keyword(channel.keyword.downcase).first.should == channel
      Channel.by_keyword(channel.keyword.swapcase).first.should == channel
    end
  end

  describe "find_by_tparty_keyword" do
    it "is case insensitive" do
      kw = Faker::Lorem.word
      TpartyKeywordValidator.any_instance.stub(:validate_each){}
      channel = create(:channel,keyword:kw,tparty_keyword:kw)
      channel = Channel.find(channel.id)
      Channel.find_by_tparty_keyword(channel.tparty_keyword.upcase).should == channel
      Channel.find_by_tparty_keyword(channel.tparty_keyword.downcase).should == channel
      Channel.find_by_tparty_keyword(channel.tparty_keyword.swapcase).should == channel
    end
  end

  describe "by_tparty_keyword" do
    it "is case insensitive" do
      kw = Faker::Lorem.word
      TpartyKeywordValidator.any_instance.stub(:validate_each){}
      channel = create(:channel,keyword:kw,tparty_keyword:kw)
      channel = Channel.find(channel.id)
      Channel.by_tparty_keyword(channel.tparty_keyword.upcase).first.should == channel
      Channel.by_tparty_keyword(channel.tparty_keyword.downcase).first.should == channel
      Channel.by_tparty_keyword(channel.tparty_keyword.swapcase).first.should == channel
    end
  end

  describe "with_subscriber" do
    it "returns the channel/channels with the given subscriber" do
      user = create(:user)
      ch1 = create(:channel,user:user)
      ch2 = create(:channel,user:user)
      phone_number = Faker::PhoneNumber.us_phone_number
      subs = create(:subscriber,phone_number:phone_number)
      ch2.subscribers << subs
      Channel.with_subscriber(phone_number).should == [Channel.find(ch2)]
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

  describe "soft delete" do
    it "is supported" do
      user = create(:user)
      ch1 = create(:channel,user:user)
      ch2 = create(:channel,user:user)
      ch1.destroy
      Channel.all.size.should == 1
      Channel.unscoped.all.size.should == 2
    end
  end

  describe "#" do
    let(:tparty_keyword) {Faker::Lorem.word}
    let(:user) {create(:user)}
    before do
      TpartyKeywordValidator.any_instance.stub(:validate_each){}
      @channel = create(:channel,user:user,tparty_keyword:tparty_keyword)
    end
    let(:channel) {@channel}
    subject {@channel}
    describe "with schedule upon creation updates next_send_time" do
      before do
        Timecop.freeze(Time.new(2013,10,19,5,0)) #Saturday
        @channel = create(:channel,schedule:IceCube::Rule.daily.hour_of_day(9))
      end
      it "properly" do
        @channel.next_send_time.should == Time.new(2013,10,19,9,0)
        @channel.schedule = IceCube::Rule.daily.hour_of_day(4)
        @channel.save
        @channel.next_send_time.should == Time.new(2013,10,20,4,0)
        @channel.schedule = IceCube::Rule.weekly.day(:monday).hour_of_day(4)
        @channel.save
        @channel.next_send_time.should == Time.new(2013,10,21,4,0)
        @channel.schedule = IceCube::Rule.weekly.day(:saturday).hour_of_day(0)
        @channel.save
        @channel.next_send_time.should == Time.new(2013,10,26,0,0)
      end
      after do
        Timecop.return
      end
    end

    describe "schedule= " do
      it "with empty schedule returns an empty hash when accessed" do
        channel = create(:channel,schedule:"{}")
        channel.schedule.should == {}
      end
    end

    it "get_all_seq_nos returns sequence numbers of all messages" do
      msg1 = create(:message,channel:channel)
      msg2 = create(:message,channel:channel)
      channel.get_all_seq_nos.should =~ [msg1.seq_no,msg2.seq_no]
    end

    it "lists all subscriber responses" do
      phone_number = Faker::PhoneNumber.us_phone_number
      sub = create(:subscriber,user:user,phone_number:phone_number)
      channel.subscribers << sub
      expect {
        create(:subscriber_response,origin:phone_number,
          tparty_keyword:channel.tparty_keyword,
          message_content:Faker::Lorem.sentence)
      }.to change{channel.subscriber_responses.count}.by 1
    end

    describe "reset_next_send_time" do
      before do
        Timecop.freeze(Time.new(2013,10,19,5,0)) #Saturday
        @channel = create(:channel,schedule:IceCube::Rule.daily.hour_of_day(9))
      end
      after do
        Timecop.return
      end
      it "works fine when schedule is daily" do
        @channel.next_send_time.should == Time.new(2013,10,19,9,0)
        Timecop.return
        Timecop.freeze(Time.new(2013,10,26,5,0))
        @channel.reset_next_send_time
        @channel.next_send_time.should == Time.new(2013,10,26,9,0)
        Timecop.return
      end
      it "works fine when schedule is weekly" do
        @channel.schedule = IceCube::Rule.weekly.day(:wednesday).hour_of_day(9)
        @channel.save
        @channel.next_send_time.should == Time.new(2013,10,23,9,0)
        Timecop.return
        Timecop.freeze(Time.new(2013,10,26,5,0))
        @channel.reset_next_send_time
        @channel.next_send_time.should == Time.new(2013,10,30,9,0)
        Timecop.return
      end
    end

    describe "sent_messages_ids and #pending_messages_ids" do
      it "returns those messages which have been sent to this subscriber" do
        subscriber = create(:subscriber,user:user)
        channel.subscribers << subscriber
        messages = []
        (0..3).each do
          message = create(:message,channel:channel)
          messages << message
        end
        channel.sent_messages_ids(subscriber).should =~ []
        channel.pending_messages_ids(subscriber).should =~ (0..3).map{|i| messages[i].id}
        DeliveryNotice.create(subscriber:subscriber,message:messages[1])
        DeliveryNotice.create(subscriber:subscriber,message:messages[2])
        channel.sent_messages_ids(subscriber).should =~ [messages[1].id,messages[2].id]
        channel.pending_messages_ids(subscriber).should =~ [messages[0].id,messages[3].id]
        DeliveryNotice.create(subscriber:subscriber,message:messages[0])
        DeliveryNotice.create(subscriber:subscriber,message:messages[3])
        channel.sent_messages_ids(subscriber).should =~ (0..3).map{|i| messages[i].id}
        channel.pending_messages_ids(subscriber).should =~ []
      end

    end

    describe "send_scheduled_messages" do
      let(:msg) {create(:message,channel:channel)}
      let(:subs1){create(:subscriber,user:user)}
      let(:subs2){create(:subscriber,user:user)}
      before do
        channel.subscribers << subs1
        channel.subscribers << subs2
      end
      it "calls group_subscribers_by_message" do
        subject.should_receive(:group_subscribers_by_message){}
        subject.send_scheduled_messages
      end

      it "for non-internal messages, uses MessagingManager to broadcast messages to right subscribers" do
        subject.stub(:group_subscribers_by_message){{msg.id=>[subs1,subs2]}}
        mm = double.as_null_object
        MessagingManager.stub(:new_instance){mm}
        mm.should_receive(:broadcast_message){|message,subscribers|
          message.should == Message.find(msg)
          subscribers.should =~ [subs1,subs2]
        }
        subject.send_scheduled_messages
      end

      it "for internal messages, calls send_to_subscribers method of the message itself instead of MessagingManager" do
        imsg = create(:action_message)
        subject.stub(:group_subscribers_by_message){{imsg.id=>[subs1,subs2]}}
        ActionMessage.any_instance.should_receive(:send_to_subscribers){|subscribers|
          subscribers.should =~ [subs1,subs2]
        }
        mm = double.as_null_object
        MessagingManager.stub(:new_instance){mm}
        mm.should_not_receive(:broadcast_message)
        subject.send_scheduled_messages
      end

      it "calls perform_post_send_ops" do
        subject.stub(:group_subscribers_by_message){{msg.id=>[subs1,subs2]}}
        mm = double.as_null_object
        MessagingManager.stub(:new_instance){mm}
        subject.should_receive(:perform_post_send_ops){}
        subject.send_scheduled_messages
      end

      it "calls perform_post_send_ops for all messages" do
        subject.stub(:group_subscribers_by_message){{msg.id=>[subs1,subs2]}}
        subject.stub(:perform_post_send_ops){}
        mm = double.as_null_object
        MessagingManager.stub(:new_instance){mm}
        message_stub = double.as_null_object
        Message.stub(:find){message_stub}
        message_stub.should_receive(:perform_post_send_ops){}
        subject.send_scheduled_messages
      end

      it "calls reset_next_send_time" do
        subject.should_receive(:reset_next_send_time){}
        subject.send_scheduled_messages
      end
    end

    describe "remove_keyword" do
      it "does not call the MessagingManagerWorker if there are other channels sharing the keyword" do
        keyword = Faker::Lorem.word
        TpartyKeywordValidator.any_instance.stub(:validate_each){}
        ch1 = create(:channel,tparty_keyword:keyword,keyword:'sample1')
        ch2 = create(:channel,tparty_keyword:keyword,keyword:'sample2')
        MessagingManagerWorker.should_not_receive(:perform_async)
        ch1.destroy
      end
    end
    it "does calls MessagingManagerWorker when all uses of keyword is deleted" do
      keyword = Faker::Lorem.word
      TpartyKeywordValidator.any_instance.stub(:validate_each){}
      ch1 = create(:channel,tparty_keyword:keyword,keyword:'sample1')
      ch2 = create(:channel,tparty_keyword:keyword,keyword:'sample2')
      MessagingManagerWorker.should_receive(:perform_async){|action,opts|
        action.should == 'remove_keyword'
        opts['keyword'].should == keyword
      }
      ch1.destroy
      ch2.destroy
    end

    describe "process_subscriber_response" do
      it "initiate start command processing on receiving start com" do
        sr = create(:subscriber_response,message_content:'start',
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_start_command){true}
        subject.process_subscriber_response(sr).should == true
      end

      it "initiates stop command processing on receiving stop command" do
        sr = create(:subscriber_response,message_content:'stop',
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_stop_command){true}
        subject.process_subscriber_response(sr).should == true
      end

      it "initiates custom command processing on receiving custom command" do
        sr = create(:subscriber_response,message_content:'',
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_custom_command)
        subject.process_subscriber_response(sr)
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:Faker::PhoneNumber.us_phone_number)
        subject.should_receive(:process_custom_command){true}
        subject.process_subscriber_response(sr).should == true
      end
    end

    describe "process_start_command" do
      it "creates a subscriber if one does not exist and adds to channel" do
        phone_number = Faker::PhoneNumber.us_phone_number
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        expect{
          subject.process_start_command(sr).should == true}.to change{
          subject.user.subscribers.count
        }.by 1
      end
      it "adds an existing subscriber to a channel if it is not already a member" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,phone_number:phone_number,user:user)
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        expect{subject.process_start_command(sr).should == true}.to change{
          subject.subscribers.count
        }.by 1
      end
      it "does not add a subscriber to the system if he is already present" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,phone_number:phone_number,user:user)
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        expect{subject.process_start_command(sr).should ==true}.to_not change{
          subject.user.subscribers.count
        }
      end
      it "does not add a subscriber to a channel if he is already present" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,phone_number:phone_number,user:user)
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        subject.subscribers << subscriber
        expect{subject.process_start_command(sr).should == true}.to_not change{
          subject.subscribers.count
        }
      end
      it "does not add a subscriber if mo subscription is not allowed" do
        phone_number = Faker::PhoneNumber.us_phone_number
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        subject.allow_mo_subscription=false
        subject.save!
        expect{subject.process_start_command(sr).should == false}.to_not change{
          subject.subscribers.count
        }
      end
      it "does not add a subscriber if mo subscription deadline is expired" do
        phone_number = Faker::PhoneNumber.us_phone_number
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        subject.mo_subscription_deadline=2.days.ago
        subject.save!
        expect{subject.process_start_command(sr).should == false}.to_not change{
          subject.subscribers.count
        }
      end
      it "creates a subscriber if one does not exist and adds to channel if mo subscription deadline is not expired" do
        phone_number = Faker::PhoneNumber.us_phone_number
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        subject.mo_subscription_deadline = 2.days.from_now
        subject.save!
        expect{
          subject.process_start_command(sr).should == true}.to change{
          subject.user.subscribers.count
        }.by 1
      end
    end

    describe "process_stop_command" do
      it "removes a subscriber from the channel if he is currently a member" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,user:user,phone_number:phone_number)
        subject.subscribers << subscriber
        sr = create(:subscriber_response,origin:phone_number,
          message_content:'stop')
        expect{subject.process_stop_command(sr).should == true}.to change{
          subject.subscribers.count
        }.by -1
      end
      it "does not remove subscriber from user" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,user:user,phone_number:phone_number)
        subject.subscribers << subscriber
        sr = create(:subscriber_response,origin:phone_number,
          message_content:'stop')
        expect{subject.process_stop_command(sr).should == true}.to_not change{
          subject.user.subscribers.count
        }
      end
      it "does not change subscriber list of channel if subscriber is not a member" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,user:user,phone_number:phone_number)
        sr = create(:subscriber_response,origin:phone_number,
          message_content:'stop')
        expect{subject.process_stop_command(sr).should == false}.to_not change{
          subject.subscribers.count
        }
      end
    end

    describe "process_custom_command" do
      it "calls process_custom_channel_command" do
        sr = create(:subscriber_response)
        subject.should_receive(:process_custom_channel_command){true}
        subject.process_custom_command(sr).should == true
      end
      it "if not channel command, associates a message with it" do
        sr = create(:subscriber_response)
        subject.stub(:process_custom_channel_command){false}
        subject.should_receive(:associate_response_with_last_primary_message){nil}
        subject.process_custom_command(sr)
      end
      it "if not channel command, asks message to process subscriber response" do
        sr = create(:subscriber_response)
        message = build(:response_message)
        subject.stub(:process_custom_channel_command){false}
        subject.stub(:associate_response_with_last_primary_message){message}
        ResponseMessage.any_instance.should_receive(:process_subscriber_response){true}
        subject.process_custom_command(sr).should == true
      end
    end

    describe "associate_response_with_last_primary_message" do
      it "sets the message field with the last primary message that required response" do
        phone_number = Faker::PhoneNumber.us_phone_number
        m1 = create(:poll_message,channel:subject)
        m2 = create(:simple_message,channel:subject)
        m3 = create(:message,channel:subject,primary:false)
        sub1 = create(:subscriber,user:user,phone_number:phone_number)
        subject.subscribers << sub1
        create(:delivery_notice,message:m1,subscriber:sub1)
        create(:delivery_notice,message:m2,subscriber:sub1)
        create(:delivery_notice,message:m3,subscriber:sub1)
        sr = create(:subscriber_response,origin:phone_number)
        subject.associate_response_with_last_primary_message(sr)
        SubscriberResponse.find(sr).message.should == Message.find(m1)
      end
    end

    it "subclasses specialize abstract methods" do
      Channel.child_classes.each do |child_class|
        ch = create(child_class.to_s.underscore.to_sym)
        expect{ch.has_schedule?}.to_not raise_error
        expect{ch.sequenced?}.to_not raise_error
        expect{ch.broadcastable?}.to_not raise_error
        expect{ch.type_abbr}.to_not raise_error
        expect{ch.individual_messages_have_schedule?}.to_not raise_error
      end
    end

  end

  it "special test case" do
    create(:channel)
  end


end
