require 'spec_helper'

describe TwilioWrapper do
  subject {TwilioWrapper}
  context 'Liveinspired.do_not_send module' do
    it 'is off in test mode' do
      expect(Liveinspired.do_not_send == true).to be_truthy
    end
    it 'can control the TwilioWrapper' do
      TwilioWrapper.mock_calls = false
      expect(TwilioWrapper.new.mock).to eq(false)
      Liveinspired.turn_off_message_sending!
      expect(TwilioWrapper.new.mock).to eq(true)
      Liveinspired.turn_on_message_sending!
      expect(TwilioWrapper.new.mock).to eq(false)
    end
  end

  context 'MOCKS and ENV' do
    it "is possible to switch on and off mocking" do
      TwilioWrapper.mock_calls = false
      expect(TwilioWrapper.new.mock).to eq(false)
      expect(TwilioWrapper.new.allowed_to_send?).to be_truthy
      TwilioWrapper.mock_calls = true
      expect(TwilioWrapper.new.mock).to eq(true)
      expect(TwilioWrapper.new.allowed_to_send?).to be_falsey
    end

    it 'will not send messages to the API if there is an ENV variable of DO_NOT_SEND' do
      ClimateControl.modify DO_NOT_SEND: 'true', RAILS_ENV: 'production' do
        expect(TwilioWrapper.new.mock).to eq(true)
        expect(TwilioWrapper.new.allowed_to_send? == false).to be_truthy
      end
    end
    it 'will not send messages in test mode' do
      ClimateControl.modify RAILS_ENV: 'test', INSPIRE_ENV: 'test' do
        tw = TwilioWrapper.new
        expect(tw.allowed_to_send? == false).to be_truthy
      end
    end
  end

  describe "instance" do
    let(:client){double}
    let(:account){double}
    let(:messages){double}
    before do
      TwilioWrapper.mock_calls = false
      allow(client).to receive(:account).and_return(account)
      allow(account).to receive(:messages).and_return(messages)
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
        expect(messages).to receive(:create){|opts|
          expect(opts[:from]).to eq(from_num)
          expect(opts[:body]).to eq(message)
          expect(opts[:media_url]).to be_nil
          expect(opts[:to]).to eq(phone_number)
        }
        subject.send_message(phone_number,
            'dummy',message,nil,from_num)
      end
      it "calls @client.account.messages.create to send mms" do
        media_url = Faker::Internet.url
        expect(messages).to receive(:create){|opts|
          expect(opts[:from]).to eq(from_num)
          expect(opts[:body]).to eq(message)
          expect(opts[:media_url]).to eq(media_url)
          expect(opts[:to]).to eq(phone_number)
        }
        subject.send_message(phone_number,
          'dummy',message,media_url,from_num)
      end

      it "returns false if send_message throws Request Error" do
        allow(messages).to receive(:create).and_raise("Twilio::REST::RequestError")
        expect(subject.send_message(phone_number,
            'dummy',message,nil,from_num)).to eq(false)
      end

    end

  end
end
