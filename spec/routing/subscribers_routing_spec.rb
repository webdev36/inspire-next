require "spec_helper"

describe SubscribersController do
  describe "routing" do

    it "routes to #index" do
      expect(get("subscribers")).to route_to controller:"subscribers",
        action:"index"
    end

    it "routes to #new" do
      expect(get("subscribers/new")).to route_to controller:"subscribers",
        action:"new"
    end

    it "routes to #show" do
      expect(get("subscribers/1")).to route_to controller:"subscribers",
        :id => "1", action:"show"
    end

    it "routes to #edit" do
      expect(get("subscribers/1/edit")).to route_to controller:"subscribers",
        :id => "1", action:"edit"
    end

    it "routes to #create" do
      expect(post("subscribers")).to route_to controller:"subscribers",
        action:"create"
    end

    it "routes to #update" do
      expect(put("subscribers/1")).to route_to controller:"subscribers",
        :id => "1", action:"update"
    end

    it "routes to #destroy" do
      expect(delete("subscribers/1")).to route_to controller:"subscribers",
        :id => "1", action:"destroy"
    end

  end
end
