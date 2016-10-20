require 'spec_helper'

describe ChannelsController do
  let(:user) {FactoryGirl.create(:user)}
  let(:valid_attributes) { attributes_for(:announcements_channel)}

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "guest user" do
    it "is redirected to signup form always and not allowed to alter db" do
      channel = user.channels.create! valid_attributes

      get :index,{}
      expect(response).to redirect_to new_user_session_path

      get :new, {}
      expect(response).to redirect_to new_user_session_path

      get :show, {:id => channel.to_param}
      expect(response).to redirect_to new_user_session_path

      get :messages_report, {:id => channel.to_param}
      expect(response).to redirect_to new_user_session_path

      get :edit, {:id => channel.to_param}
      expect(response).to redirect_to new_user_session_path

      expect {
            post :create, {:channel => valid_attributes}
          }.to_not change(Channel, :count).by(1)

      Channel.any_instance.should_not_receive(:update_attributes)
      put :update, {:id => channel.to_param, :channel => { "name" => "MyString" }}

      expect {
          delete :destroy, {:id => channel.to_param}
      }.to_not change(Channel, :count).by(-1)

      get :list_subscribers, {:id => channel.to_param}
      expect(response).to redirect_to new_user_session_path

      subscriber = create(:subscriber,user:user)
      expect {
        post :add_subscriber, {channel_id:channel.to_param, id:subscriber.to_param }
      }.to_not change(channel.subscribers, :count).by(1)

      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      expect {
        post :remove_subscriber, {channel_id:channel.to_param, id:subscriber.to_param }
      }.to_not change(channel.subscribers, :count).by(-1)

    end
  end

  describe "one user" do
    it "cannot access other user channels" do
      channel = user.channels.create! valid_attributes
      another_user = create(:user)
      sign_in another_user

      get :show, {:id => channel.to_param}
      expect(response).to redirect_to root_url

      get :messages_report, {:id => channel.to_param}
      expect(response).to redirect_to root_url      

      get :edit, {:id => channel.to_param}
      expect(response).to redirect_to root_url

      Channel.any_instance.should_not_receive(:update_attributes)
      put :update, {:id => channel.to_param, :channel => { "name" => "MyString" }}

      expect {
          delete :destroy, {:id => channel.to_param}
      }.to_not change(Channel, :count).by(-1)     
      
      get :list_subscribers, {:id => channel.to_param}
      expect(response).to redirect_to root_url

      subscriber = create(:subscriber,user:user)
      expect {
        post :add_subscriber, {channel_id:channel.to_param, id:subscriber.to_param }
      }.to_not change(channel.subscribers, :count).by(1)

      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      expect {
        post :remove_subscriber, {channel_id:channel.to_param, id:subscriber.to_param }
      }.to_not change(channel.subscribers, :count).by(-1)

    end
  end
  describe "valid user" do
    before do
      sign_in(user)
    end
    describe "GET index" do
      before do
        @channels = (0..2).map{create(:channel,user:user)}
        @channels = Channel.find(@channels.map(&:id))
        @channel_group = create(:channel_group,user:user)        
      end
      it "assigns channels and channel_groups" do
        get :index, {}
        assigns(:channels).should =~ @channels
        assigns(:channel_groups).should =~ [@channel_group]
      end
      it "does not list channels part of group in @channels" do
        @channel_group.channels << @channels[1]
        get :index, {}
        assigns(:channels).should =~ [@channels[0],@channels[2]]
        assigns(:channel_groups).should =~ [@channel_group]
      end
    end 
    describe "GET show" do
      it "assigns the requested channel as @channel" do
        channel = user.channels.create! valid_attributes
        channel = user.channels.find(channel.id)
        subscribers = (0..2).map {create(:subscriber,user:user)}
        channel.subscribers << subscribers
        get :show, {user_id:user.to_param, :id => channel.to_param}
        assigns(:channel).should eq(channel)
        assigns(:subscribers).should =~ subscribers
      end
    end    
    describe "GET new" do
      it "assigns a new channel as @channel" do
        get :new, {user_id:user.to_param}
        assigns(:channel).should be_a_new(Channel)
      end
    end
    describe "GET edit" do
      it "assigns the requested channel as @channel" do
        channel = user.channels.create! valid_attributes
        channel = Channel.find(channel.id)
        get :edit, {user_id:user.to_param,:id => channel.to_param}
        assigns(:channel).should eq(channel)
      end
    end
    describe "POST create" do
      describe "with valid params" do
        it "creates a new Channel" do
          expect {
            post :create, {:channel => valid_attributes}
          }.to change(Channel, :count).by(1)
        end

        it "assigns a newly created channel as @channel" do
          post :create, {:channel => valid_attributes}
          assigns(:channel).should be_a(Channel)
          assigns(:channel).should be_persisted
        end

        it "redirects to the created channel" do
          post :create, {user_id:user.to_param,:channel => valid_attributes}
          response.should redirect_to(Channel.last)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved channel as @channel" do
          # Trigger the behavior that occurs when invalid params are submitted
          Channel.any_instance.stub(:save).and_return(false)
          post :create, {user_id:user.to_param, :channel => { "name" => "invalid value" }}
          assigns(:channel).should be_a_new(Channel)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          Channel.any_instance.stub(:save).and_return(false)
          post :create, {user_id:user.to_param, :channel => { "name" => "invalid value" }}
          response.should render_template("new")
        end
      end
    end   
    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested channel" do
          channel = user.channels.create! valid_attributes
          # Assuming there are no other channels in the database, this
          # specifies that the Channel created on the previous line
          # receives the :update_attributes message with whatever params are
          # submitted in the request.
          Channel.any_instance.should_receive(:update_attributes).with({ "name" => "MyString" })
          put :update, {:id => channel.to_param, :channel => { "name" => "MyString" }}
        end

        it "assigns the requested channel as @channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          put :update, {:id => channel.to_param, :channel => valid_attributes}
          assigns(:channel).should eq(channel)
        end

        it "redirects to the channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          put :update, {:id => channel.to_param, :channel => valid_attributes}
          response.should redirect_to(channel)
        end
      end

      describe "with invalid params" do
        it "assigns the channel as @channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          # Trigger the behavior that occurs when invalid params are submitted
          Channel.any_instance.stub(:save).and_return(false)
          put :update, {:id => channel.to_param, :channel => { "name" => "invalid value" }}
          assigns(:channel).should eq(channel)
        end

        it "re-renders the 'edit' template" do
          channel = user.channels.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          Channel.any_instance.stub(:save).and_return(false)
          put :update, {:id => channel.to_param, :channel => { "name" => "invalid value" }}
          response.should render_template("edit")
        end
      end
    end   
    describe "DELETE destroy" do
      it "destroys the requested channel" do
        channel = user.channels.create! valid_attributes
        expect {
          delete :destroy, {:id => channel.to_param}
        }.to change(Channel, :count).by(-1)
      end

      it "redirects to the channels list" do
        channel = user.channels.create! valid_attributes
        delete :destroy, {:id => channel.to_param}
        response.should redirect_to(user_url(user))
      end
    end   
    describe "GET list_subscribers" do
      it "assigns subscribed and unsubscribed subscribers" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        subscribed_subs = [subs[0],subs[1]]
        unsubscribed_subs = [subs[2]]        
        get :list_subscribers, {id:ch}
        assigns(:channel).should eq(ch)
        assigns(:subscribed_subscribers).should =~ subscribed_subs
        assigns(:unsubscribed_subscribers).should =~ unsubscribed_subs       
      end
      it "works when there are no subscribers yet for a channel" do
        ch = create(:channel, user:user)
        ch = Channel.find(ch)
        subs = (0..2).map{create(:subscriber,user:user)}
        subscribed_subs = []
        unsubscribed_subs = [subs[0],subs[1],subs[2]]        
        get :list_subscribers, {id:ch}
        assigns(:channel).should eq(ch)
        assigns(:subscribed_subscribers).should =~ subscribed_subs
        assigns(:unsubscribed_subscribers).should =~ unsubscribed_subs
      end
    end 
    describe "POST add_subscriber" do
      it "should increase subscribed subscribers array by one" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        new_sub = subs[2]
        expect {
          post :add_subscriber, {channel_id:ch.id, id:new_sub.id}
        }.to change(ch.subscribers,:count).by(1)
      end
      it "should redirect to channel subscriber list" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        new_sub = subs[2]
        post :add_subscriber, {channel_id:ch.id, id:new_sub.id}
        response.should redirect_to(list_subscribers_channel_url(ch))
      end      
    end  
    describe "POST remove_subscriber" do
      it "should decrease subscribed subscribers array by one" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch)
        subs = (0..1).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        sub_to_remove = subs[1]
        expect {
          post :remove_subscriber, {channel_id:ch.id, id:sub_to_remove.id}
        }.to change(ch.subscribers,:count).by(-1)
      end
      it "should redirect to channel subscriber list" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch)
        subs = (0..1).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        sub_to_remove = subs[1]
        post :remove_subscriber, {channel_id:ch.id, id:sub_to_remove.id}
        response.should redirect_to(list_subscribers_channel_url(ch))
      end      
    end              
  end


end
