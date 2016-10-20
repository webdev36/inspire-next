require 'spec_helper'

describe MessagingManager do
  describe 'new_instance' do
    it 'returns TwilioMessagingManager by default' do
      stub_const('ENV',ENV.to_hash.merge('TPARTY_MESSAGING_SYSTEM'=>''))
      MessagingManager.new_instance.class.should == TwilioMessagingManager
    end

    it 'returns TwilioMessagingManager when specified' do
      stub_const('ENV',ENV.to_hash.merge('TPARTY_MESSAGING_SYSTEM'=>'Twilio'))
      MessagingManager.new_instance.class.should == TwilioMessagingManager
    end
  end
  describe 'mmclass' do
    it 'returns TwilioMessagingManager by default' do
      stub_const('ENV',ENV.to_hash.merge('TPARTY_MESSAGING_SYSTEM'=>''))
      MessagingManager.mmclass.should == TwilioMessagingManager
    end

    it 'returns TwilioMessagingManager when specified' do
      stub_const('ENV',ENV.to_hash.merge('TPARTY_MESSAGING_SYSTEM'=>'Twilio'))
      MessagingManager.mmclass.should == TwilioMessagingManager
    end
  end

  describe 'substitute_placeholders' do
    subject {MessagingManager}
    it 'substitutes placeholders as per the substitute string' do
      subject.substitute_placeholders("Hello %%Salutations%% %%Name%%. How are you today?",
          "Salutations=Mr.;Name=John Doe").should == 'Hello Mr. John Doe. How are you today?'
    end

    it 'substitutes placeholders insensitive to case' do
      subject.substitute_placeholders("Hello %%Salutations%% %%Name%%. How are you today?",
          "salutations=Mr.;name=John Doe").should == 'Hello Mr. John Doe. How are you today?'
    end

    it 'leaves string intact if placeholders are not present in string' do
      subject.substitute_placeholders("Hello Mrs. Jane Doe. How are you today?",
          "salutations=Mr.;name=John Doe").should == 'Hello Mrs. Jane Doe. How are you today?'
    end

    it 'substitutes missing placeholders with empty string' do
      subject.substitute_placeholders("Hello %%Salutations%% %%Name%%. How are you today?",
          "name=John Doe").should == 'Hello  John Doe. How are you today?'

      subject.substitute_placeholders("Hello %%Salutations%%. How are you today?",
          nil).should == 'Hello . How are you today?'
    end

    it "substitutes placeholders even when they occur more than once" do
    subject.substitute_placeholders("Hello %%Salutations%% %%Name%%. You are %%Salutations%% %%Name%%, right?",
        "Salutations=Mr.;Name=John Doe").should == 'Hello Mr. John Doe. You are Mr. John Doe, right?'
    end

  end

  describe '#' do
    subject {MessagingManager.new}
    describe "broadcast_message" do
      it "calls send_message method" do
        mw = double
        message = double
        my_title = Faker::Lorem.sentence
        my_caption = Faker::Lorem.sentence
        my_content_url = Faker::Internet.url
        content = OpenStruct.new({url:my_content_url,exists?:true})
        message.stub(:title){my_title}
        message.stub(:channel){nil}
        message.stub(:caption){my_caption}
        message.stub(:content){content}
        message.stub(:options){{}}
        message.stub(:primary?){true}
        message.stub(:id){4242}
        sub1 = double
        sub2 = double
        phone_numbers=[Faker::PhoneNumber.us_phone_number,Faker::PhoneNumber.us_phone_number]
        sub1.stub(:phone_number){phone_numbers[0]}
        sub2.stub(:phone_number){phone_numbers[1]}
        sub1.stub(:id){4242}
        sub2.stub(:id){424242}
        subscribers = [sub1,sub2]
        ret_phone_numbers=[]
        subject.stub(:send_message){|phone_number,title,caption,content_url,from_num|
          ret_phone_numbers << phone_number
          title.should == my_title
          caption.should == my_caption
          content_url.should == my_content_url
        }
        DeliveryNotice.stub(:create){}
        subject.broadcast_message(message,subscribers)
        ret_phone_numbers.should =~ phone_numbers
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
        subject.should_receive(:send_message){|phone_number,subject,msg,content_url,from_num|
          msg.should == "#{message.caption} #{channel.suffix}"
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
        subject.stub(:send_message){true}
        expect{
          subject.broadcast_message(message,[subs1,subs2])
          }.to change{DeliveryNotice.count}.by(2)
      end
    end

  end
end
