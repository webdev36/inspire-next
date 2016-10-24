require "spec_helper"

describe TwilioController do
  describe "routing" do
    it "routes to #callback" do
      expect(post("twilio")).to route_to controller:'twilio',action:'callback'
    end
  end
end