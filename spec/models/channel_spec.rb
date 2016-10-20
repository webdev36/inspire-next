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
    allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
    create(:channel,keyword:'sample',tparty_keyword:'sample')
    expect(build(:channel,keyword:'sample',tparty_keyword:'sample')).to_not be_valid
  end

  it "allows similar keyword across different tparty_keyword" do
    allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
    create(:channel,keyword:'sample',tparty_keyword:'sample1')
    expect(build(:channel,keyword:'sample',tparty_keyword:'sample2')).to be_valid
  end

  it "validates tparty_keyword to check if primary or is available" do
    expect_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){|record,attribute,value|
      expect(attribute).to eq(:tparty_keyword)
      expect(value).to eq('sample')
    }
    create(:channel,keyword:'sample',tparty_keyword:'sample')
  end

  it "validates one_word to ensure it is only a single word" do
    expect_any_instance_of(OneWordValidator).to receive(:validate_each){|record,attribute,value|
      expect(attribute).to eq(:one_word)
      expect(value).to eq('sample')
    }
    create(:channel,one_word:'sample')
  end

  it "validates moderator emails are valid" do
    expect_any_instance_of(EmailsValidator).to receive(:validate_each){|record,attribute,value|
      expect(attribute).to eq(:moderator_emails)
      expect(value).to eq('abc@def.com')
    }
    create(:channel,moderator_emails:'abc@def.com')
  end

  it "allows moderator_emails to be blank" do
    expect_any_instance_of(EmailsValidator).not_to receive(:validate_each){}
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
    expect(ch2).not_to be_valid
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
    expect(ch2).to be_valid
  end

  it "upon creation calls MessagingManagerWorker to create keyword if required" do
      allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
      keyword = Faker::Lorem.word
      expect(MessagingManagerWorker).to receive(:perform_async){|action,opts|
        expect(action).to eq('add_keyword')
        expect(opts['keyword']).to eq(keyword)
      }
      create(:channel,tparty_keyword:keyword)
  end

  it "upon destroy calls MessagingManagerWorker to remove keyword if required" do
    channel = create(:channel)
    expect(MessagingManagerWorker).to receive(:perform_async){|action,opts|
      expect(action).to eq('remove_keyword')
      expect(opts['keyword']).to eq(channel.tparty_keyword)
    }
    channel.destroy
  end

  it "ensures the same subscriber is not added more than once" do
    user = create(:user)
    channel = create(:channel,user:user)
    subscriber = create(:subscriber,user:user)
    channel.subscribers << subscriber
    expect(channel.subscribers.count).to eq(1)
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
    expect(AnnouncementsChannel.model_name).to eq(Channel.model_name)
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
    expect(Channel.pending_send).to match_array([channel1,channel2])
  end

  describe "get_next_seq_no" do
    it "returns first seq no if current is nil or 0" do
      expect(Channel.get_next_seq_no(nil,[1,2,3])).to eq(1)
      expect(Channel.get_next_seq_no(0,[1,2,3])).to eq(1)
    end
    it "returns correct seq no" do
      expect(Channel.get_next_seq_no(3,[1,2,3,5])).to eq(5)
    end
    it "returns nil if there are no larger seq_no" do
      expect(Channel.get_next_seq_no(5,[1,2,3,5])).to eq(nil)
    end

  end

  describe "find_by_keyword" do
    it "is case insensitive" do
      channel = create(:channel,keyword:'SampleKeyword')
      channel = Channel.find(channel.id)
      expect(Channel.find_by_keyword(channel.keyword.upcase)).to eq(channel)
      expect(Channel.find_by_keyword(channel.keyword.downcase)).to eq(channel)
      expect(Channel.find_by_keyword(channel.keyword.swapcase)).to eq(channel)
    end
  end

  describe "by_keyword" do
    it "is case insensitive" do
      channel = create(:channel,keyword:'SampleKeyword')
      channel = Channel.find(channel.id)
      expect(Channel.by_keyword(channel.keyword.upcase).first).to eq(channel)
      expect(Channel.by_keyword(channel.keyword.downcase).first).to eq(channel)
      expect(Channel.by_keyword(channel.keyword.swapcase).first).to eq(channel)
    end
  end

  describe "find_by_tparty_keyword" do
    it "is case insensitive" do
      kw = Faker::Lorem.word
      allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
      channel = create(:channel,keyword:kw,tparty_keyword:kw)
      channel = Channel.find(channel.id)
      expect(Channel.find_by_tparty_keyword(channel.tparty_keyword.upcase)).to eq(channel)
      expect(Channel.find_by_tparty_keyword(channel.tparty_keyword.downcase)).to eq(channel)
      expect(Channel.find_by_tparty_keyword(channel.tparty_keyword.swapcase)).to eq(channel)
    end
  end

  describe "by_tparty_keyword" do
    it "is case insensitive" do
      kw = Faker::Lorem.word
      allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
      channel = create(:channel,keyword:kw,tparty_keyword:kw)
      channel = Channel.find(channel.id)
      expect(Channel.by_tparty_keyword(channel.tparty_keyword.upcase).first).to eq(channel)
      expect(Channel.by_tparty_keyword(channel.tparty_keyword.downcase).first).to eq(channel)
      expect(Channel.by_tparty_keyword(channel.tparty_keyword.swapcase).first).to eq(channel)
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
      expect(Channel.with_subscriber(phone_number)).to eq([Channel.find(ch2)])
    end
  end

  describe "identify_command" do
    it "identifies start command" do
      expect(Channel.identify_command('Start')).to eq(:start)
    end
    it "identifies stop command" do
      expect(Channel.identify_command('Stop')).to eq(:stop)
    end
    it "identifies custom single word command" do
      expect(Channel.identify_command(Faker::Lorem.word)).to eq(:custom)
    end
    it "identifies custom multi word command" do
      expect(Channel.identify_command(Faker::Lorem.sentence)).to eq(:custom)
    end
  end

  describe "soft delete" do
    it "is supported" do
      user = create(:user)
      ch1 = create(:channel,user:user)
      ch2 = create(:channel,user:user)
      ch1.destroy
      expect(Channel.all.size).to eq(1)
      expect(Channel.unscoped.all.size).to eq(2)
    end
  end

  describe "#" do
    let(:tparty_keyword) {Faker::Lorem.word}
    let(:user) {create(:user)}
    before do
      allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
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
        expect(@channel.next_send_time).to eq(Time.new(2013,10,19,9,0))
        @channel.schedule = IceCube::Rule.daily.hour_of_day(4)
        @channel.save
        expect(@channel.next_send_time).to eq(Time.new(2013,10,20,4,0))
        @channel.schedule = IceCube::Rule.weekly.day(:monday).hour_of_day(4)
        @channel.save
        expect(@channel.next_send_time).to eq(Time.new(2013,10,21,4,0))
        @channel.schedule = IceCube::Rule.weekly.day(:saturday).hour_of_day(0)
        @channel.save
        expect(@channel.next_send_time).to eq(Time.new(2013,10,26,0,0))
      end
      after do
        Timecop.return
      end
    end

    describe "schedule= " do
      it "with empty schedule returns an empty hash when accessed" do
        channel = create(:channel,schedule:"{}")
        expect(channel.schedule).to eq({})
      end
    end

    it "get_all_seq_nos returns sequence numbers of all messages" do
      msg1 = create(:message,channel:channel)
      msg2 = create(:message,channel:channel)
      expect(channel.get_all_seq_nos).to match_array([msg1.seq_no,msg2.seq_no])
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
        expect(@channel.next_send_time).to eq(Time.new(2013,10,19,9,0))
        Timecop.return
        Timecop.freeze(Time.new(2013,10,26,5,0))
        @channel.reset_next_send_time
        expect(@channel.next_send_time).to eq(Time.new(2013,10,26,9,0))
        Timecop.return
      end
      it "works fine when schedule is weekly" do
        @channel.schedule = IceCube::Rule.weekly.day(:wednesday).hour_of_day(9)
        @channel.save
        expect(@channel.next_send_time).to eq(Time.new(2013,10,23,9,0))
        Timecop.return
        Timecop.freeze(Time.new(2013,10,26,5,0))
        @channel.reset_next_send_time
        expect(@channel.next_send_time).to eq(Time.new(2013,10,30,9,0))
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
        expect(channel.sent_messages_ids(subscriber)).to match_array([])
        expect(channel.pending_messages_ids(subscriber)).to match((0..3).map{|i| messages[i].id})
        DeliveryNotice.create(subscriber:subscriber,message:messages[1])
        DeliveryNotice.create(subscriber:subscriber,message:messages[2])
        expect(channel.sent_messages_ids(subscriber)).to match_array([messages[1].id,messages[2].id])
        expect(channel.pending_messages_ids(subscriber)).to match_array([messages[0].id,messages[3].id])
        DeliveryNotice.create(subscriber:subscriber,message:messages[0])
        DeliveryNotice.create(subscriber:subscriber,message:messages[3])
        expect(channel.sent_messages_ids(subscriber)).to match((0..3).map{|i| messages[i].id})
        expect(channel.pending_messages_ids(subscriber)).to match_array([])
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
        expect(subject).to receive(:group_subscribers_by_message){}
        subject.send_scheduled_messages
      end

      it "for non-internal messages, uses MessagingManager to broadcast messages to right subscribers" do
        allow(subject).to receive(:group_subscribers_by_message){{msg.id=>[subs1,subs2]}}
        mm = double.as_null_object
        allow(MessagingManager).to receive(:new_instance){mm}
        expect(mm).to receive(:broadcast_message){|message,subscribers|
          expect(message).to eq(Message.find(msg))
          expect(subscribers).to match_array([subs1,subs2])
        }
        subject.send_scheduled_messages
      end

      it "for internal messages, calls send_to_subscribers method of the message itself instead of MessagingManager" do
        imsg = create(:action_message)
        allow(subject).to receive(:group_subscribers_by_message){{imsg.id=>[subs1,subs2]}}
        expect_any_instance_of(ActionMessage).to receive(:send_to_subscribers){|subscribers|
          expect(subscribers).to match_array([subs1,subs2])
        }
        mm = double.as_null_object
        allow(MessagingManager).to receive(:new_instance){mm}
        expect(mm).not_to receive(:broadcast_message)
        subject.send_scheduled_messages
      end

      it "calls perform_post_send_ops" do
        allow(subject).to receive(:group_subscribers_by_message){{msg.id=>[subs1,subs2]}}
        mm = double.as_null_object
        allow(MessagingManager).to receive(:new_instance){mm}
        expect(subject).to receive(:perform_post_send_ops){}
        subject.send_scheduled_messages
      end

      it "calls perform_post_send_ops for all messages" do
        allow(subject).to receive(:group_subscribers_by_message){{msg.id=>[subs1,subs2]}}
        allow(subject).to receive(:perform_post_send_ops){}
        mm = double.as_null_object
        allow(MessagingManager).to receive(:new_instance){mm}
        message_stub = double.as_null_object
        allow(Message).to receive(:find){message_stub}
        expect(message_stub).to receive(:perform_post_send_ops){}
        subject.send_scheduled_messages
      end

      it "calls reset_next_send_time" do
        expect(subject).to receive(:reset_next_send_time){}
        subject.send_scheduled_messages
      end
    end

    describe "remove_keyword" do
      it "does not call the MessagingManagerWorker if there are other channels sharing the keyword" do
        keyword = Faker::Lorem.word
        allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
        ch1 = create(:channel,tparty_keyword:keyword,keyword:'sample1')
        ch2 = create(:channel,tparty_keyword:keyword,keyword:'sample2')
        expect(MessagingManagerWorker).not_to receive(:perform_async)
        ch1.destroy
      end
    end
    it "does calls MessagingManagerWorker when all uses of keyword is deleted" do
      keyword = Faker::Lorem.word
      allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
      ch1 = create(:channel,tparty_keyword:keyword,keyword:'sample1')
      ch2 = create(:channel,tparty_keyword:keyword,keyword:'sample2')
      expect(MessagingManagerWorker).to receive(:perform_async){|action,opts|
        expect(action).to eq('remove_keyword')
        expect(opts['keyword']).to eq(keyword)
      }
      ch1.destroy
      ch2.destroy
    end

    describe "process_subscriber_response" do
      it "initiate start command processing on receiving start com" do
        sr = create(:subscriber_response,message_content:'start',
          origin:Faker::PhoneNumber.us_phone_number)
        expect(subject).to receive(:process_start_command){true}
        expect(subject.process_subscriber_response(sr)).to eq(true)
      end

      it "initiates stop command processing on receiving stop command" do
        sr = create(:subscriber_response,message_content:'stop',
          origin:Faker::PhoneNumber.us_phone_number)
        expect(subject).to receive(:process_stop_command){true}
        expect(subject.process_subscriber_response(sr)).to eq(true)
      end

      it "initiates custom command processing on receiving custom command" do
        sr = create(:subscriber_response,message_content:'',
          origin:Faker::PhoneNumber.us_phone_number)
        expect(subject).to receive(:process_custom_command)
        subject.process_subscriber_response(sr)
        sr = create(:subscriber_response,message_content:Faker::Lorem.sentence,
          origin:Faker::PhoneNumber.us_phone_number)
        expect(subject).to receive(:process_custom_command){true}
        expect(subject.process_subscriber_response(sr)).to eq(true)
      end
    end

    describe "process_start_command" do
      it "creates a subscriber if one does not exist and adds to channel" do
        phone_number = Faker::PhoneNumber.us_phone_number
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        expect{
          expect(subject.process_start_command(sr)).to eq(true)}.to change{
          subject.user.subscribers.count
        }.by 1
      end
      it "adds an existing subscriber to a channel if it is not already a member" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,phone_number:phone_number,user:user)
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        expect{expect(subject.process_start_command(sr)).to eq(true)}.to change{
          subject.subscribers.count
        }.by 1
      end
      it "does not add a subscriber to the system if he is already present" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,phone_number:phone_number,user:user)
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        expect{expect(subject.process_start_command(sr)).to eq(true)}.to_not change{
          subject.user.subscribers.count
        }
      end
      it "does not add a subscriber to a channel if he is already present" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,phone_number:phone_number,user:user)
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        subject.subscribers << subscriber
        expect{expect(subject.process_start_command(sr)).to eq(true)}.to_not change{
          subject.subscribers.count
        }
      end
      it "does not add a subscriber if mo subscription is not allowed" do
        phone_number = Faker::PhoneNumber.us_phone_number
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        subject.allow_mo_subscription=false
        subject.save!
        expect{expect(subject.process_start_command(sr)).to eq(false)}.to_not change{
          subject.subscribers.count
        }
      end
      it "does not add a subscriber if mo subscription deadline is expired" do
        phone_number = Faker::PhoneNumber.us_phone_number
        sr = create(:subscriber_response,message_content:'start',
          origin:phone_number)
        subject.mo_subscription_deadline=2.days.ago
        subject.save!
        expect{expect(subject.process_start_command(sr)).to eq(false)}.to_not change{
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
          expect(subject.process_start_command(sr)).to eq(true)}.to change{
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
        expect{expect(subject.process_stop_command(sr)).to eq(true)}.to change{
          subject.subscribers.count
        }.by -1
      end
      it "does not remove subscriber from user" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,user:user,phone_number:phone_number)
        subject.subscribers << subscriber
        sr = create(:subscriber_response,origin:phone_number,
          message_content:'stop')
        expect{expect(subject.process_stop_command(sr)).to eq(true)}.to_not change{
          subject.user.subscribers.count
        }
      end
      it "does not change subscriber list of channel if subscriber is not a member" do
        phone_number = Faker::PhoneNumber.us_phone_number
        subscriber = create(:subscriber,user:user,phone_number:phone_number)
        sr = create(:subscriber_response,origin:phone_number,
          message_content:'stop')
        expect{expect(subject.process_stop_command(sr)).to eq(false)}.to_not change{
          subject.subscribers.count
        }
      end
    end

    describe "process_custom_command" do
      it "calls process_custom_channel_command" do
        sr = create(:subscriber_response)
        expect(subject).to receive(:process_custom_channel_command){true}
        expect(subject.process_custom_command(sr)).to eq(true)
      end
      it "if not channel command, associates a message with it" do
        sr = create(:subscriber_response)
        allow(subject).to receive(:process_custom_channel_command){false}
        expect(subject).to receive(:associate_response_with_last_primary_message){nil}
        subject.process_custom_command(sr)
      end
      it "if not channel command, asks message to process subscriber response" do
        sr = create(:subscriber_response)
        message = build(:response_message)
        allow(subject).to receive(:process_custom_channel_command){false}
        allow(subject).to receive(:associate_response_with_last_primary_message){message}
        expect_any_instance_of(ResponseMessage).to receive(:process_subscriber_response){true}
        expect(subject.process_custom_command(sr)).to eq(true)
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
        expect(SubscriberResponse.find(sr).message).to eq(Message.find(m1))
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
