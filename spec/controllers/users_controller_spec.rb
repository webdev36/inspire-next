require 'spec_helper'

describe UsersController do
  let(:user) {FactoryGirl.create(:user)}

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "guest user" do
    it "is redirected to signup form" do
      get :show,{id:user.to_param}
      expect(response).to redirect_to new_user_session_path
    end
  end

  describe "one user" do
    it "cannot access other user channels" do
      another_user = create(:user)
      sign_in another_user

      get :show, {:id => user.to_param}
      expect(response).to redirect_to root_url
    end
  end

  describe "valid user" do
    before do
      sign_in(user)
    end
    describe "GET show" do
      before do
        @channels = (0..2).map{create(:channel,user:user)}
        @channels = Channel.find(@channels.map(&:id))
        @channel_group = create(:channel_group,user:user)
        @subscribers = (0..2).map {create(:subscriber,user:user)}
      end
      it "assigns the channels, channel groups and subscribers" do
        get :show, {id:user.id}
        assigns(:channels).should  =~ @channels
        assigns(:subscribers).should =~ @subscribers
        assigns(:channel_groups).should =~ [@channel_group]
      end
      it "does not list channels that are part of group in @channels" do
        @channel_group.channels << @channels[1]
        get :show, {id:user.id}
        assigns(:channels).should  =~ [@channels[0],@channels[2]]
        assigns(:subscribers).should =~ @subscribers
      end      

    end    
  end
end
