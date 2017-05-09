

FactoryGirl.define do
  factory :inbound_twilio_message, class:Hash do
    defaults = {
                  "ToCountry"=>"US",
                  "ToState"=>"DC",
                  "SmsMessageSid"=>"SM6982f4dd88bacc2b5b0fd39518a23ddd",
                  "NumMedia"=>"0",
                  "ToCity"=>"WASHINGTON",
                  "FromZip"=>"20782",
                  "SmsSid"=>"SM6982f4dd88bacc2b5b0fd39518a23ddd",
                  "FromState"=>"DC",
                  "SmsStatus"=>"received",
                  "FromCity"=>"WASHINGTON",
                  "Body"=>"testswitchto2 start",
                  "FromCountry"=>"US",
                  "To"=>"+12025551212",
                  "ToZip"=>"20388",
                  "NumSegments"=>"1",
                  "MessageSid"=> "SM6982f4dd88bacc2b5b0fd39518a23ddd",
                  "AccountSid"=>"AC96abab99e4c7074745084fd920d120f0",
                  "From"=>"+12024866066",
                  "ApiVersion"=>"2010-04-01",
                  "controller"=>"twilio",
                  "action"=>"callback"
                }
    initialize_with { ActionController::Parameters.new(defaults.merge(attributes)) }
  end
end
