require 'spec_helper'

describe TwilioWrapper do
  subject {TwilioWrapper}
  
  it "is possible to switch on and off mocking" do
    TwilioWrapper.mock_calls = false
    TwilioWrapper.new.mock.should == false
    TwilioWrapper.mock_calls = true
    TwilioWrapper.new.mock.should == true
  end

  it "default during test is mock on" do
    TwilioWrapper.new.mock.should == true
  end

  describe "instance" do
    let(:client){double}
    let(:account){double}
    let(:messages){double}
    before do
      TwilioWrapper.mock_calls = false
      client.stub(:account).and_return(account)
      account.stub(:messages).and_return(messages)
    end
    after do
      TwilioWrapper.mock_calls = true
    end
    subject {TwilioWrapper.new(client)}

    describe "send_message" do
      let(:message) {Faker::Lorem.sentence}
      let(:phone_number){Faker::PhoneNumber.us_phone_number}
      let(:from_num){Faker::PhoneNumber.us_phone_number}
      it "calls @client.account.messages.create to send sms" do
        messages.should_receive(:create){|opts|
          opts[:from].should == from_num
          opts[:body].should == message
          opts[:media_url].should be_nil
          opts[:to].should == phone_number
        }
        subject.send_message(phone_number,
            'dummy',message,nil,from_num)
      end
      it "calls @client.account.messages.create to send mms" do
        media_url = Faker::Internet.url
        messages.should_receive(:create){|opts|
          opts[:from].should == from_num
          opts[:body].should == message
          opts[:media_url].should == media_url
          opts[:to].should == phone_number
        }
        subject.send_message(phone_number,
          'dummy',message,media_url,from_num)
      end

      it "returns false if send_message throws Request Error" do 
        messages.stub(:create).and_raise("Twilio::REST::RequestError")
        subject.send_message(phone_number,
            'dummy',message,nil,from_num).should == false
      end

    end

  end
end