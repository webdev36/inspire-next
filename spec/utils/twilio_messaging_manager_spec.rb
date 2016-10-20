require 'spec_helper'

describe TwilioMessagingManager do
  it 'is a keyword based provider' do
    TwilioMessagingManager.keyword_based_service?.should be_false
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
        TwilioWrapper.stub(:new){tw}
        tw.should_receive(:send_message){|pphone_number,ptitle,pcaption,pcontent_url,pfrom_num|
          pphone_number.should == phone_number
          ptitle.should == title
          pcaption.should == caption
          pcontent_url.should == content_url
          pfrom_num.should == from_num
        }
        subject.send_message(phone_number,title,caption,content_url,from_num)
      end
      it "returns false if wrapper fails" do 
        tw = double 
        TwilioWrapper.stub(:new){tw}
        tw.should_receive(:send_message).and_return(false)
        subject.send_message(phone_number,title,caption,content_url,from_num).should == false
      end
    end

    it "validate_tparty_keyword always returns true since twilio does not support tparty keyword" do
      subject.validate_tparty_keyword('sample').should be_nil
    end

    it "add_keyword always returns true since twilio does not support tparty keyword" do
      subject.add_keyword('sample').should == true
    end

    it "remove_keyword always returns true since twilio does not support tparty keyword" do
      subject.remove_keyword('sample').should == true
    end

    it 'is not a keyword based provider' do
      subject.keyword_based_service?.should be_false
    end

  end

end