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

      get :show, { id: channel.id}
      expect(response).to redirect_to new_user_session_path

      get :messages_report, { id: channel.id }
      expect(response).to redirect_to new_user_session_path

      get :edit, {:id => channel.id }
      expect(response).to redirect_to new_user_session_path

      expect {
            post :create, {:channel => valid_attributes}
          }.to_not change(Channel, :count)

      expect_any_instance_of(Channel).not_to receive(:update_attributes)
      put :update, {:id => channel.id, :channel => { "name" => "MyString" }}

      expect {
          delete :destroy, {:id => channel.id}
      }.to_not change(Channel, :count)

      get :list_subscribers, {:id => channel.id}
      expect(response).to redirect_to new_user_session_path

      subscriber = create(:subscriber,user:user)
      expect {
        post :add_subscriber, {channel_id:channel.id, id:subscriber.id }
      }.to_not change(channel.subscribers, :count)

      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      expect {
        post :remove_subscriber, {channel_id:channel.id, id:subscriber.id }
      }.to_not change(channel.subscribers, :count)

    end
  end

  describe "one user" do
    it "cannot access other user channels" do
      channel = user.channels.create! valid_attributes
      another_user = create(:user)
      sign_in another_user

      get :show, {:id => channel.id}
      expect(response).to redirect_to root_url

      get :messages_report, {:id => channel.id}
      expect(response).to redirect_to root_url

      get :edit, {:id => channel.id}
      expect(response).to redirect_to root_url

      expect_any_instance_of(Channel).not_to receive(:update_attributes)
      put :update, {:id => channel.id, :channel => { "name" => "MyString" }}

      expect {
          delete :destroy, {:id => channel.id}
      }.to_not change(Channel, :count)

      get :list_subscribers, {:id => channel.id}
      expect(response).to redirect_to root_url

      subscriber = create(:subscriber,user:user)
      expect {
        post :add_subscriber, {channel_id:channel.id, id:subscriber.id }
      }.to_not change(channel.subscribers, :count)

      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      expect {
        post :remove_subscriber, {channel_id:channel.id, id:subscriber.id }
      }.to_not change(channel.subscribers, :count)

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
        expect(assigns(:channels).map(&:id).sort).to match(@channels.map(&:id).sort)
        expect(assigns(:channel_groups).map(&:id).sort).to match([@channel_group.id])
      end
      it "does not list channels part of group in @channels" do
        @channel_group.channels << @channels[1]
        get :index, {}
        expect(assigns(:channels)).to match_array([@channels[0],@channels[2]])
        expect(assigns(:channel_groups)).to match_array([@channel_group])
      end
    end
    describe "GET show" do
      it "assigns the requested channel as @channel" do
        channel = user.channels.create! valid_attributes
        channel = user.channels.find(channel.id)
        subscribers = (0..2).map {create(:subscriber,user:user)}
        channel.subscribers << subscribers
        get :show, {user_id:user.id, :id => channel.id}
        expect(assigns(:channel)).to eq(channel)
        expect(assigns(:subscribers)).to match(subscribers)
      end
    end
    describe "GET new" do
      it "assigns a new channel as @channel" do
        get :new, {user_id:user.id}
        expect(assigns(:channel)).to be_a_new(Channel)
      end
    end
    describe "GET edit" do
      it "assigns the requested channel as @channel" do
        channel = user.channels.create! valid_attributes
        channel = Channel.find(channel.id)
        get :edit, {user_id:user.id,:id => channel.id}
        expect(assigns(:channel)).to eq(channel)
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
          expect(assigns(:channel)).to be_a(Channel)
          expect(assigns(:channel)).to be_persisted
        end

        it "redirects to the created channel" do
          post :create, {user_id:user.id,:channel => valid_attributes}
          expect(response).to redirect_to(Channel.last)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved channel as @channel" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Channel).to receive(:save).and_return(false)
          post :create, {user_id:user.id, :channel => { "name" => "invalid value" }}
          expect(assigns(:channel)).to be_a_new(Channel)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Channel).to receive(:save).and_return(false)
          post :create, {user_id:user.id, :channel => { "name" => "invalid value" }}
          expect(response).to render_template("new")
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
          expect_any_instance_of(Channel).to receive(:update_attributes).with({ "name" => "MyString" })
          put :update, {:id => channel.id, :channel => { "name" => "MyString" }}
        end

        it "assigns the requested channel as @channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          put :update, {:id => channel.id, :channel => valid_attributes}
          expect(assigns(:channel)).to eq(channel)
        end

        it "redirects to the channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          put :update, {:id => channel.id, :channel => valid_attributes}
          expect(response).to redirect_to(channel)
        end
      end

      describe "with invalid params" do
        it "assigns the channel as @channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Channel).to receive(:save).and_return(false)
          put :update, {:id => channel.id, :channel => { "name" => "invalid value" }}
          expect(assigns(:channel)).to eq(channel)
        end

        it "re-renders the 'edit' template" do
          channel = user.channels.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Channel).to receive(:save).and_return(false)
          put :update, {:id => channel.id, :channel => { "name" => "invalid value" }}
          expect(response).to render_template("edit")
        end
      end
    end
    describe "DELETE destroy" do
      it "destroys the requested channel" do
        channel = user.channels.create! valid_attributes
        expect {
          delete :destroy, {:id => channel.id}
        }.to change(Channel, :count).by(-1)
      end

      it "redirects to the channels list" do
        channel = user.channels.create! valid_attributes
        delete :destroy, {:id => channel.id}
        expect(response).to redirect_to(user_url(user))
      end
    end
    describe "GET list_subscribers" do
      it "assigns subscribed and unsubscribed subscribers" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        subscribed_subs = [subs[0],subs[1]]
        unsubscribed_subs = [subs[2]]
        get :list_subscribers, {id:ch}
        expect(assigns(:channel)).to eq(ch)
        expect(assigns(:subscribed_subscribers)).to match(subscribed_subs)
        expect(assigns(:unsubscribed_subscribers)).to match(unsubscribed_subs)
      end

      it "works when there are no subscribers yet for a channel" do
        ch = create(:channel, user:user)
        ch = Channel.find(ch.id)
        subs = (0..2).map{create(:subscriber,user:user)}
        subscribed_subs = []
        unsubscribed_subs = [subs[0],subs[1],subs[2]]
        get :list_subscribers, {id: ch.id}
        expect(assigns(:channel)).to eq(ch)
        expect(assigns(:subscribed_subscribers)).to match(subscribed_subs)
        expect(assigns(:unsubscribed_subscribers).map(&:id).sort).to match(unsubscribed_subs.map(&:id).sort)
      end

    end
    describe "POST add_subscriber" do
      it "should increase subscribed subscribers array by one" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        new_sub = subs[2]
        request.env["HTTP_REFERER"] = "/channels/#{ch.id}"
        expect {
          post :add_subscriber, {channel_id:ch.id, id:new_sub.id}
        }.to change(ch.subscribers,:count).by(1)
      end
      it "should redirect to channel subscriber list" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        new_sub = subs[2]
        request.env["HTTP_REFERER"] = "/channels/#{ch.id}"
        post :add_subscriber, {channel_id:ch.id, id:new_sub.id}
        expect(response).to redirect_to("/channels/#{ch.id}")
      end
    end
    describe "POST remove_subscriber" do
      it "should decrease subscribed subscribers array by one" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..1).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        sub_to_remove = subs[1]
        request.env["HTTP_REFERER"] = "/channels/#{ch.id}"
        expect {
          post :remove_subscriber, {channel_id:ch.id, id:sub_to_remove.id}
        }.to change(ch.subscribers,:count).by(-1)
      end
      it "should redirect back to the original poster" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..1).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        sub_to_remove = subs[1]
        request.env["HTTP_REFERER"] = "/channels/#{ch.id}"
        post :remove_subscriber, {channel_id:ch.id, id:sub_to_remove.id}
        expect(response).to redirect_to("/channels/#{ch.id}")
      end
    end
  end
end
