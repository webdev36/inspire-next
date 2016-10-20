require "spec_helper"

describe SubscriberActivitiesController do
  describe "routing" do

    it "routes to #index" do
      get("subscriber_activities").should route_to controller:"subscriber_activities",
        action:"index"
    end

    it "routes to #show" do
      get("subscriber_activities/1").should route_to controller:"subscriber_activities",
        :id => "1", action:"show"
    end

    it "routes to #edit" do
      get("subscriber_activities/1/edit").should route_to controller:"subscriber_activities",
        :id => "1", action:"edit"
    end

    it "routes to #update" do
      put("subscriber_activities/1").should route_to controller:"subscriber_activities",
        :id => "1", action:"update"
    end

    it "routes to #reprocess" do
      post("subscriber_activities/1/reprocess").should route_to controller:"subscriber_activities",
        :id => "1", action:"reprocess"
    end    

  end
end
