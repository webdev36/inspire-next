require 'spec_helper'

describe ChannelGroupsController do
  let(:user) {FactoryGirl.create(:user)}
  let(:valid_attributes) { attributes_for(:channel_group)}

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "guest user" do
    it "is redirected to signup form always and not allowed to alter db" do
      channel_group = user.channel_groups.create! valid_attributes

      get :new, {}
      expect(response).to redirect_to new_user_session_path

      get :show, { id: channel_group.to_param }
      expect(response).to redirect_to new_user_session_path

      get :messages_report, { id: channel_group.to_param }
      expect(response).to redirect_to new_user_session_path

      get :edit, { id: channel_group.to_param }
      expect(response).to redirect_to new_user_session_path

      expect {
            post :create, { channel_group: valid_attributes }
          }.to_not change(ChannelGroup, :count)

      expect_any_instance_of(ChannelGroup).not_to receive(:update_attributes)
      put :update, { id: channel_group.to_param, channel_group: { name: "MyString" }}

      expect {
          delete :destroy, {:id => channel_group.to_param}
      }.to_not change(ChannelGroup, :count)

      channel = create(:channel, user:user)
      channel_group.channels << channel
      expect {
        post :remove_channel, { channel_group_id: channel_group.id, id: channel.id }
      }.to_not change(channel_group.channels, :count)

    end
  end

  describe "one user" do
    it "cannot access other user channel_groups" do
      channel_group = user.channel_groups.create! valid_attributes
      another_user = create(:user)
      sign_in another_user

      get :show, { id: channel_group.id }
      expect(response).to redirect_to root_url

      get :messages_report, { id: channel_group.id }
      expect(response).to redirect_to root_url


      get :edit, { id: channel_group.id }
      expect(response).to redirect_to root_url

      expect_any_instance_of(ChannelGroup).not_to receive(:update_attributes)
      put :update, {id: channel_group.id, channel: { name: "MyString" }}

      expect {
          delete :destroy, { id: channel_group.id }
      }.to_not change(ChannelGroup, :count)

      channel = create(:channel, user:user)
      channel_group.channels << channel
      expect {
        post :remove_channel, { channel_group_id: channel_group.id, id: channel.id }
      }.to_not change(channel_group.channels, :count)
    end
  end
  describe "valid user" do
    before do
      sign_in(user)
    end
    describe "GET show" do
      it "assigns the requested channel_group as @channel_group" do
        channel_group = user.channel_groups.create! valid_attributes
        channel_group = user.channel_groups.find(channel_group.id)
        channels = (0..2).map {create(:channel,user:user)}
        channels = (0..2).map {|i| Channel.find(channels[i].id)}
        channel_group.channels << channels
        get :show, { user_id:user.id, id: channel_group.id }
        expect(assigns(:channel_group)).to eq(channel_group)
        expect(assigns(:channels)).to match(channels)
      end
    end
    describe "GET new" do
      it "assigns a new channel as @channel" do
        get :new, { user_id: user.id }
        expect(assigns(:channel_group)).to be_a_new(ChannelGroup)
      end
    end
    describe "GET edit" do
      it "assigns the requested channel_group as @channel_group" do
        channel_group = user.channel_groups.create! valid_attributes
        channel_group = ChannelGroup.find(channel_group.id)
        get :edit, { user_id: user.id, id: channel_group.id }
        expect(assigns(:channel_group)).to eq(channel_group)
      end
    end
    describe "POST create" do
      describe "with valid params" do
        it "creates a new ChannelGroup" do
          expect {
            post :create, { :channel_group => valid_attributes }
          }.to change(ChannelGroup, :count).by(1)
        end

        it "assigns a newly created channel group as @channel_group" do
          post :create, { :channel_group => valid_attributes }
          expect(assigns(:channel_group)).to be_a(ChannelGroup)
          expect(assigns(:channel_group)).to be_persisted
        end

        it "redirects to the created channel_group" do
          post :create, { user_id:user.id, :channel_group => valid_attributes }
          expect(response).to redirect_to(ChannelGroup.last)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved channel as @channel" do
          allow_any_instance_of(ChannelGroup).to receive(:save).and_return(false)
          post :create, {user_id: user.id, :channel_group => { "name" => "invalid value" }}
          expect(assigns(:channel_group)).to be_a_new(ChannelGroup)
        end

        it "re-renders the 'new' template" do
          allow_any_instance_of(ChannelGroup).to receive(:save).and_return(false)
          post :create, {user_id: user.id, :channel_group => { "name" => "invalid value" }}
          expect(response).to render_template("new")
        end
      end
    end
    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested channel_group" do
          channel_group = user.channel_groups.create! valid_attributes
          expect_any_instance_of(ChannelGroup).to receive(:update_attributes).with({ "name" => "MyString" })
          put :update, {:id => channel_group.id, :channel_group => { "name" => "MyString" }}
        end

        it "assigns the requested channel_group as @channel_group" do
          channel_group = user.channel_groups.create! valid_attributes
          channel_group = ChannelGroup.find(channel_group.id)
          put :update, {:id => channel_group.id, :channel_group => valid_attributes}
          expect(assigns(:channel_group)).to eq(channel_group)
        end

        it "redirects to the channel" do
          channel_group = user.channel_groups.create! valid_attributes
          channel_group = ChannelGroup.find(channel_group.id)
          put :update, {:id => channel_group.id, :channel_group => valid_attributes}
          expect(response).to redirect_to(channel_group)
        end
      end

      describe "with invalid params" do
        it "assigns the channel group as @channel_group" do
          channel_group = user.channel_groups.create! valid_attributes
          channel_group = ChannelGroup.find(channel_group.id)
          allow_any_instance_of(ChannelGroup).to receive(:save).and_return(false)
          put :update, {:id => channel_group.id, :channel_group => { "name" => "invalid value" }}
          expect(assigns(:channel_group)).to eq(channel_group)
        end

        it "re-renders the 'edit' template" do
          channel_group = user.channel_groups.create! valid_attributes
          allow_any_instance_of(ChannelGroup).to receive(:save).and_return(false)
          put :update, {:id => channel_group.id, :channel_group => { "name" => "invalid value" }}
          expect(response).to render_template("edit")
        end
      end
    end
    describe "DELETE destroy" do
      it "destroys the requested channel_group" do
        channel_group = user.channel_groups.create! valid_attributes
        expect {
          delete :destroy, {:id => channel_group.id}
        }.to change(ChannelGroup, :count).by(-1)
      end

      it "redirects to the user path" do
        channel_group = user.channel_groups.create! valid_attributes
        delete :destroy, { :id => channel_group.id }
        expect(response).to redirect_to(user_path(user))
      end
    end
    describe "POST remove_channel" do
      it "should decrease member channels array by one" do
        ch_group = create(:channel_group,user:user)
        channels = (0..1).map{create(:channel,user:user)}
        (0..1).each{|i| ch_group.channels << channels[i]}
        channel_to_remove = channels[1]
        expect {
          post :remove_channel, {channel_group_id:ch_group.id, id:channel_to_remove.id}
        }.to change(ch_group.channels,:count).by(-1)
      end
      it "should redirect to channel group page" do
        ch_group = create(:channel_group,user:user)
        channels = (0..1).map{create(:channel,user:user)}
        (0..1).each{|i| ch_group.channels << channels[i]}
        channel_to_remove = channels[1]
        post :remove_channel, {channel_group_id:ch_group.id, id:channel_to_remove.id}
        expect(response).to redirect_to(channel_group_url(ch_group))
      end
    end

  end


end
