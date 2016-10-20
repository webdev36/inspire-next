require "spec_helper"

describe MessagesController do
  describe "routing" do

    it "routes to #index" do
      expect(get("channels/2/messages")).to route_to controller:'messages',
        channel_id:"2", action:'index'
    end

    it "routes to #new" do
      expect(get("channels/2/messages/new")).to route_to controller:'messages',
        channel_id:"2", action:'new'
    end

    it "routes to #show" do
      expect(get("channels/2/messages/1")).to route_to controller:'messages',
        channel_id:"2", id:"1", action:'show'
    end

    it "routes to #edit" do
      expect(get("channels/2/messages/1/edit")).to route_to controller:'messages',
        channel_id:"2", id:"1", action:'edit'
    end

    it "routes to #create" do
      expect(post("channels/2/messages")).to route_to controller:'messages',
        channel_id:"2", action:'create'
    end

    it "routes to #update" do
      expect(put("channels/2/messages/1")).to route_to controller:'messages',
        channel_id:"2", id:"1", action:'update'
    end

    it "routes to #destroy" do
      expect(delete("channels/2/messages/1")).to route_to controller:'messages',
        channel_id:"2", id:"1", action:'destroy'
    end

    it "routes to #broadcast" do
      expect(post("channels/2/messages/1/broadcast")).to route_to controller:'messages',
        channel_id: "2", id:"1", action:'broadcast'
    end

    it "routes to #move_up" do
      expect(post("channels/2/messages/1/move_up")).to route_to controller:'messages',
        channel_id: "2", id:"1", action:'move_up'
    end

    it "routes to #responses" do
      expect(get("channels/2/messages/1/responses")).to route_to controller:'messages',
        channel_id:"2", id:"1", action:'responses'
    end    
    

    it "routes to #select_import" do
      expect(get("channels/2/messages/select_import")).to route_to controller:'messages',
        channel_id:"2",action:"select_import"
    end

    it "routes to #import" do
      expect(post("channels/2/messages/import")).to route_to controller:'messages',
        channel_id:"2",action:"import"
    end    
  end
end
