require "spec_helper"

describe MessagesController do
  describe "routing" do

    it "routes to #index" do
      get("channels/2/messages").should route_to controller:'messages',
        channel_id:"2", action:'index'
    end

    it "routes to #new" do
      get("channels/2/messages/new").should route_to controller:'messages',
        channel_id:"2", action:'new'
    end

    it "routes to #show" do
      get("channels/2/messages/1").should route_to controller:'messages',
        channel_id:"2", id:"1", action:'show'
    end

    it "routes to #edit" do
      get("channels/2/messages/1/edit").should route_to controller:'messages',
        channel_id:"2", id:"1", action:'edit'
    end

    it "routes to #create" do
      post("channels/2/messages").should route_to controller:'messages',
        channel_id:"2", action:'create'
    end

    it "routes to #update" do
      put("channels/2/messages/1").should route_to controller:'messages',
        channel_id:"2", id:"1", action:'update'
    end

    it "routes to #destroy" do
      delete("channels/2/messages/1").should route_to controller:'messages',
        channel_id:"2", id:"1", action:'destroy'
    end

    it "routes to #broadcast" do
      post("channels/2/messages/1/broadcast").should route_to controller:'messages',
        channel_id: "2", id:"1", action:'broadcast'
    end

    it "routes to #move_up" do
      post("channels/2/messages/1/move_up").should route_to controller:'messages',
        channel_id: "2", id:"1", action:'move_up'
    end

    it "routes to #responses" do
      get("channels/2/messages/1/responses").should route_to controller:'messages',
        channel_id:"2", id:"1", action:'responses'
    end    
    

    it "routes to #select_import" do
      get("channels/2/messages/select_import").should route_to controller:'messages',
        channel_id:"2",action:"select_import"
    end

    it "routes to #import" do
      post("channels/2/messages/import").should route_to controller:'messages',
        channel_id:"2",action:"import"
    end    
  end
end
