require 'spec_helper'

describe TwilioController do

  it "post to callback will fail if the system cannot process message" do
    allow_any_instance_of(TwilioController).to receive(:handle_request){false}
    post :callback
    expect(response.status).to eq(500)
  end

  it "post to callback will succeed if the system could process message" do
    allow_any_instance_of(TwilioController).to receive(:handle_request){true}
    post :callback
    expect(response.status).to eq(200)
  end

  describe "#" do
    describe "handle_request" do
      it "returns false if there is no Body param in request" do
        expect(subject.send(:handle_request,{})).to be_falsey
      end
      
      it "returns false if body param is blank" do
        expect(subject.send(:handle_request,{'Body'=>''})).to be_falsey
      end
      
      it "returns true if Body param is non-blank" do
        expect(subject.send(:handle_request,{'Body'=>Faker::Lorem.sentence,'From'=>Faker::PhoneNumber.us_phone_number})).to be_truthy
      end
      
      it "creates a SubscriberResponse object if Body param is non-blank" do
        expect {
          subject.send(:handle_request,{'Body'=>Faker::Lorem.sentence,'From'=>Faker::PhoneNumber.us_phone_number})
          }.to change{SubscriberResponse.count}.by 1
      end   

      it "initiates processing of SubscriberResponse for valid messages" do
        expect_any_instance_of(SubscriberResponse).to receive(:try_processing) {}
        subject.send(:handle_request,{'Body'=>Faker::Lorem.sentence,'From'=>Faker::PhoneNumber.us_phone_number})
      end

      it "returns false if From is blank" do
        expect(subject.send(:handle_request,{'Body'=>Faker::Lorem.sentence})).to be_falsey
      end   
    end    
  end
end
