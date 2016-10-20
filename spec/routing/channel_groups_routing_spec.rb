require "spec_helper"

describe ChannelGroupsController do
  describe "routing" do

    it "routes to #new" do
      expect(get("/channel_groups/new")).to route_to("channel_groups#new")
    end

    it "routes to #show" do
      expect(get("/channel_groups/1")).to route_to("channel_groups#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/channel_groups/1/edit")).to route_to("channel_groups#edit", :id => "1")
    end

    it "routes to #create" do
      expect(post("/channel_groups")).to route_to("channel_groups#create")
    end

    it "routes to #update" do
      expect(put("/channel_groups/1")).to route_to("channel_groups#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/channel_groups/1")).to route_to("channel_groups#destroy", :id => "1")
    end

    it "routes to #messages_report" do
      expect(get("/channel_groups/1/messages_report")).to route_to(
        "channel_groups#messages_report", :id => "1")
    end    

    it "routes to #remove_channel" do
      expect(post("channel_groups/2/remove_channel/3")).to route_to controller:'channel_groups',
        channel_group_id:'2',action:'remove_channel',id:'3'
    end        


  end
end
