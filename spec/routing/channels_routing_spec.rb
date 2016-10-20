require "spec_helper"

describe ChannelsController do
  describe "routing" do

    it "routes to #index" do
      get("channels").should route_to controller:'channels',action:'index'
    end

    it "routes to #new" do
      get("channels/new").should route_to controller:'channels',action:'new'
    end

    it "routes to #show" do
      get("channels/2").should route_to controller:'channels',
        :id => "2",action:'show'
    end

    it "routes to #edit" do
      get("channels/2/edit").should route_to controller:'channels',
        :id => "2",action:'edit'
    end

    it "routes to #create" do
      post("channels").should route_to controller:'channels',
       action:'create'
    end

    it "routes to #update" do
      put("channels/2").should route_to controller:'channels',
        :id => "2",action:'update'
    end

    it "routes to #destroy" do
      delete("channels/2").should route_to controller:'channels',
        id: "2",action:'destroy'
    end

    it "routes to #list_subscribers" do
      get("channels/2/list_subscribers").should route_to controller:'channels',
        id:'2',action:'list_subscribers'
    end

    it "routes to #add_subscriber" do
      post("channels/2/add_subscriber/3").should route_to controller:'channels',
        channel_id:'2',action:'add_subscriber',id:'3'
    end

    it "routes to #remove_subscriber" do
      post("channels/2/remove_subscriber/3").should route_to controller:'channels',
        channel_id:'2',action:'remove_subscriber',id:'3'
    end      

    it "routes to #messages_report" do
      get("/channels/1/messages_report").should route_to(
        "channels#messages_report", :id => "1")
    end       

  end
end
