require 'spec_helper'

describe TwilioMessagingManager do
  it 'is a keyword based provider' do
    expect(TwilioMessagingManager.keyword_based_service?).to be_falsey
  end    
  describe "#" do
    subject {TwilioMessagingManager.new}
    describe "send_message" do  
      let(:phone_number) {Faker::PhoneNumber.us_phone_number}
      let(:title) {Faker::Lorem.sentence}
      let(:caption) {Faker::Lorem.sentence}
      let(:content_url) {Faker::Internet.url}
      let(:from_num) {Faker::PhoneNumber.us_phone_number}
      it "calls TwilioWrapper#send_message" do
        tw = double 
        allow(TwilioWrapper).to receive(:new){tw}
        expect(tw).to receive(:send_message){|pphone_number,ptitle,pcaption,pcontent_url,pfrom_num|
          expect(pphone_number).to eq(phone_number)
          expect(ptitle).to eq(title)
          expect(pcaption).to eq(caption)
          expect(pcontent_url).to eq(content_url)
          expect(pfrom_num).to eq(from_num)
        }
        subject.send_message(phone_number,title,caption,content_url,from_num)
      end
      it "returns false if wrapper fails" do 
        tw = double 
        allow(TwilioWrapper).to receive(:new){tw}
        expect(tw).to receive(:send_message).and_return(false)
        expect(subject.send_message(phone_number,title,caption,content_url,from_num)).to eq(false)
      end
    end

    it "validate_tparty_keyword always returns true since twilio does not support tparty keyword" do
      expect(subject.validate_tparty_keyword('sample')).to be_nil
    end

    it "add_keyword always returns true since twilio does not support tparty keyword" do
      expect(subject.add_keyword('sample')).to eq(true)
    end

    it "remove_keyword always returns true since twilio does not support tparty keyword" do
      expect(subject.remove_keyword('sample')).to eq(true)
    end

    it 'is not a keyword based provider' do
      expect(subject.keyword_based_service?).to be_falsey
    end

  end

end