require "spec_helper"

describe ChannelGroupsController do
  describe "routing" do

    it "routes to #new" do
      get("/channel_groups/new").should route_to("channel_groups#new")
    end

    it "routes to #show" do
      get("/channel_groups/1").should route_to("channel_groups#show", :id => "1")
    end

    it "routes to #edit" do
      get("/channel_groups/1/edit").should route_to("channel_groups#edit", :id => "1")
    end

    it "routes to #create" do
      post("/channel_groups").should route_to("channel_groups#create")
    end

    it "routes to #update" do
      put("/channel_groups/1").should route_to("channel_groups#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/channel_groups/1").should route_to("channel_groups#destroy", :id => "1")
    end

    it "routes to #messages_report" do
      get("/channel_groups/1/messages_report").should route_to(
        "channel_groups#messages_report", :id => "1")
    end    

    it "routes to #remove_channel" do
      post("channel_groups/2/remove_channel/3").should route_to controller:'channel_groups',
        channel_group_id:'2',action:'remove_channel',id:'3'
    end        


  end
end
