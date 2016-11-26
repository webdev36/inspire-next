require 'spec_helper'

describe MessagingManager do
  describe 'new_instance' do
    it 'returns TwilioMessagingManager by default' do
      stub_const('ENV',ENV.to_hash.merge('TPARTY_MESSAGING_SYSTEM'=>''))
      expect(MessagingManager.new_instance.class).to eq(TwilioMessagingManager)
    end

    it 'returns TwilioMessagingManager when specified' do
      stub_const('ENV',ENV.to_hash.merge('TPARTY_MESSAGING_SYSTEM'=>'Twilio'))
      expect(MessagingManager.new_instance.class).to eq(TwilioMessagingManager)
    end
  end
  describe 'mmclass' do
    it 'returns TwilioMessagingManager by default' do
      stub_const('ENV',ENV.to_hash.merge('TPARTY_MESSAGING_SYSTEM'=>''))
      expect(MessagingManager.mmclass).to eq(TwilioMessagingManager)
    end

    it 'returns TwilioMessagingManager when specified' do
      stub_const('ENV',ENV.to_hash.merge('TPARTY_MESSAGING_SYSTEM'=>'Twilio'))
      expect(MessagingManager.mmclass).to eq(TwilioMessagingManager)
    end
  end

  describe 'substitute_placeholders' do
    subject {MessagingManager}
    it 'substitutes placeholders as per the substitute string' do
      expect(subject.substitute_placeholders("Hello %%Salutations%% %%Name%%. How are you today?",
          "Salutations=Mr.;Name=John Doe")).to eq('Hello Mr. John Doe. How are you today?')
    end

    it 'substitutes placeholders insensitive to case' do
      expect(subject.substitute_placeholders("Hello %%Salutations%% %%Name%%. How are you today?",
          "salutations=Mr.;name=John Doe")).to eq('Hello Mr. John Doe. How are you today?')
    end

    it 'leaves string intact if placeholders are not present in string' do
      expect(subject.substitute_placeholders("Hello Mrs. Jane Doe. How are you today?",
          "salutations=Mr.;name=John Doe")).to eq('Hello Mrs. Jane Doe. How are you today?')
    end

    it 'substitutes missing placeholders with empty string' do
      expect(subject.substitute_placeholders("Hello %%Salutations%% %%Name%%. How are you today?",
          "name=John Doe")).to eq('Hello  John Doe. How are you today?')

      expect(subject.substitute_placeholders("Hello %%Salutations%%. How are you today?",
          nil)).to eq('Hello . How are you today?')
    end

    it "substitutes placeholders even when they occur more than once" do
    expect(subject.substitute_placeholders("Hello %%Salutations%% %%Name%%. You are %%Salutations%% %%Name%%, right?",
        "Salutations=Mr.;Name=John Doe")).to eq('Hello Mr. John Doe. You are Mr. John Doe, right?')
    end
  end

  describe 'ratelimit' do
    let(:mm)    { MessagingManager.new }
    let(:phone) { Faker::PhoneNumber.us_phone_number }
    context 'does rate limiting math correctly' do
      it 'counts times correctly' do
        # the bucket_span and budket_interval settings have ot be correct
        # for us to get the right counts.. ify ou set the tracked time interval
        # to more than 1 hour, then things get messy.
        6.times do
          mm.rate_limiter.add(phone)
        end
        expect(mm.rate_limiter.count(phone, 3600) == 6).to be_truthy
      end
    end
    context 'rate limiting' do
      it 'limits on an hourly schedule' do
        ClimateControl.modify 'RATE_LIMIT_THRESHOLD': '1', 'SKIP_RATE_LIMITING': 'false' do
          travel_to_string_time('January 1, 2017 12:00')
          setup_user_and_system
          6.times do
            create_simple_message(@channel, "Day 1 12:00")
          end
          expect(Message.count == 6).to be_truthy
          @channel.subscribers << @subscriber
          travel_to_string_time("January 2, 2017 12:00")
          [0, 3, 6, 9, 12, 15].each do |time_increment|
            travel_to_same_day_at(12, time_increment)
            run_worker!
          end
          expect(DeliveryNotice.count == 1).to be_truthy
          expect(DeliveryErrorNotice.count == 5).to be_truthy
          expect(DeliveryErrorNotice.first.options['error'].include?('Phone number (across')).to be_truthy
        end
      end
    end
  end

  describe '#' do
    subject { MessagingManager.new }
    describe "broadcast_message" do
      it "calls send_message method" do
        mw = double
        message = double
        my_title = Faker::Lorem.sentence
        my_caption = Faker::Lorem.sentence
        my_content_url = Faker::Internet.url
        content = OpenStruct.new({url:my_content_url,exists?:true})
        allow(message).to receive(:title){my_title}
        allow(message).to receive(:channel){nil}
        allow(message).to receive(:caption){my_caption}
        allow(message).to receive(:content){content}
        allow(message).to receive(:options){{}}
        allow(message).to receive(:primary?){true}
        allow(message).to receive(:id){4242}
        sub1 = double
        sub2 = double
        phone_numbers=[Faker::PhoneNumber.us_phone_number,Faker::PhoneNumber.us_phone_number]
        allow(sub1).to receive(:phone_number){phone_numbers[0]}
        allow(sub2).to receive(:phone_number){phone_numbers[1]}
        allow(sub1).to receive(:id){4242}
        allow(sub2).to receive(:id){424242}
        subscribers = [sub1,sub2]
        ret_phone_numbers=[]
        allow(subject).to receive(:send_message){|phone_number,title,caption,content_url,from_num|
          ret_phone_numbers << phone_number
          expect(title).to eq(my_title)
          expect(caption).to eq(my_caption)
          expect(content_url).to eq(my_content_url)
        }
        allow(DeliveryNotice).to receive(:create){}
        subject.broadcast_message(message, subscribers)
        expect(ret_phone_numbers).to match(phone_numbers)
      end

      it "adds any channel suffix to message before send" do
        user = create(:user)
        channel = create(:channel)
        channel.suffix = Faker::Lorem.sentence
        channel.save
        message = create(:message,channel:channel)
        subscriber = create(:subscriber, user:user)
        channel.subscribers << subscriber
        mw = double
        expect(subject).to receive(:send_message){|phone_number,subject,msg,content_url,from_num|
          expect(msg).to eq("#{message.caption} #{channel.suffix}")
        }
        subject.broadcast_message(message,[subscriber])
      end

      it "adds delivery notices for the respective subscribers and messages" do
        user = create(:user)
        channel = create(:announcements_channel)
        message = create(:message,channel:channel)
        subs1 = create(:subscriber,user:user)
        subs2 = create(:subscriber,user:user)
        channel.subscribers << subs1
        channel.subscribers << subs2
        allow(subject).to receive(:send_message){true}
        expect{
          subject.broadcast_message(message,[subs1,subs2])
          }.to change{DeliveryNotice.count}.by(2)
      end
    end

  end
end
