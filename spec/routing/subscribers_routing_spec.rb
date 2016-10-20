require "spec_helper"

describe SubscribersController do
  describe "routing" do

    it "routes to #index" do
      get("subscribers").should route_to controller:"subscribers",
        action:"index"
    end

    it "routes to #new" do
      get("subscribers/new").should route_to controller:"subscribers",
        action:"new"
    end

    it "routes to #show" do
      get("subscribers/1").should route_to controller:"subscribers",
        :id => "1", action:"show"
    end

    it "routes to #edit" do
      get("subscribers/1/edit").should route_to controller:"subscribers",
        :id => "1", action:"edit"
    end

    it "routes to #create" do
      post("subscribers").should route_to controller:"subscribers",
        action:"create"
    end

    it "routes to #update" do
      put("subscribers/1").should route_to controller:"subscribers",
        :id => "1", action:"update"
    end

    it "routes to #destroy" do
      delete("subscribers/1").should route_to controller:"subscribers",
        :id => "1", action:"destroy"
    end

  end
end
