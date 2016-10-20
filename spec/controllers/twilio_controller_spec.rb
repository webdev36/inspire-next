require 'spec_helper'

describe TwilioController do

  it "post to callback will fail if the system cannot process message" do
    TwilioController.any_instance.stub(:handle_request){false}
    post :callback
    response.status.should == 500
  end

  it "post to callback will succeed if the system could process message" do
    TwilioController.any_instance.stub(:handle_request){true}
    post :callback
    response.status.should == 200
  end

  describe "#" do
    describe "handle_request" do
      it "returns false if there is no Body param in request" do
        subject.send(:handle_request,{}).should be_false
      end
      
      it "returns false if body param is blank" do
        subject.send(:handle_request,{'Body'=>''}).should be_false
      end
      
      it "returns true if Body param is non-blank" do
        subject.send(:handle_request,{'Body'=>Faker::Lorem.sentence,'From'=>Faker::PhoneNumber.us_phone_number}).should be_true
      end
      
      it "creates a SubscriberResponse object if Body param is non-blank" do
        expect {
          subject.send(:handle_request,{'Body'=>Faker::Lorem.sentence,'From'=>Faker::PhoneNumber.us_phone_number})
          }.to change{SubscriberResponse.count}.by 1
      end   

      it "initiates processing of SubscriberResponse for valid messages" do
        SubscriberResponse.any_instance.should_receive(:try_processing) {}
        subject.send(:handle_request,{'Body'=>Faker::Lorem.sentence,'From'=>Faker::PhoneNumber.us_phone_number})
      end

      it "returns false if From is blank" do
        subject.send(:handle_request,{'Body'=>Faker::Lorem.sentence}).should be_false
      end   
    end    
  end
end
