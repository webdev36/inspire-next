require 'spec_helper'

describe  SubscriberActivitiesController do   
  it "does not recognize the new,create and destory actions" do
    expect {get :new, {}}.to raise_error(ActionController::RoutingError)
    expect {post :create, {}}.to raise_error(ActionController::RoutingError)
    expect {delete :destroy, {}}.to raise_error(ActionController::RoutingError)
  end
  let(:user){create(:user)}
  let(:channel) {create(:channel,user:user)}
  let(:channel_group) {create(:channel_group,user:user)}
  let(:message) {create(:message,channel:channel)}
  let(:subscriber) {create(:subscriber,user:user)}
  let(:subscriber_response){create(:subscriber_response,message:message,subscriber:subscriber,channel:channel)}
  let(:other_subscriber_response){create(:subscriber_response,channel:channel)}
  let(:channel_group_response){create(:subscriber_response,channel_group:channel_group)}
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    channel.subscribers << subscriber
  end
  
  describe "guest user" do
    it "is redirected to signup form always and not allowed to alter db" do
      get :index, {subscriber_id:subscriber}
      expect(response).to redirect_to new_user_session_path

      get :show, {subscriber_id:subscriber,:id => subscriber_response.to_param}
      expect(response).to redirect_to new_user_session_path

      get :edit, {subscriber_id:subscriber,:id => subscriber_response.to_param}
      expect(response).to redirect_to new_user_session_path

      expect_any_instance_of(SubscriberResponse).not_to receive(:update_attributes)
      put :update, {subscriber_id:subscriber,:id => subscriber_response.to_param, :caption => "Some Caption"}

      expect_any_instance_of(SubscriberResponse).not_to receive(:process)
      post :reprocess, {subscriber_id:subscriber,:id => subscriber_response.to_param, :caption => "Some Caption"}

    end
  end

  describe "one user" do
    it "is not be able to access other user's subscriber activities" do
      another_user = create(:user)
      sign_in another_user

      get :index, {subscriber_id:subscriber}
      expect(response).to redirect_to root_url

      get :show, {subscriber_id:subscriber,:id => subscriber_response.to_param}
      expect(response).to redirect_to root_url

      get :edit, {subscriber_id:subscriber,:id => subscriber_response.to_param}
      expect(response).to redirect_to root_url

      expect_any_instance_of(SubscriberActivity).not_to receive(:update_attributes)
      put :update, {subscriber_id:subscriber,:id => subscriber_response.to_param, :caption => "Some Caption"}

      expect_any_instance_of(SubscriberActivity).not_to receive(:process)
      post :reprocess, {subscriber_id:subscriber,:id => subscriber_response.to_param, :caption => "Some Caption"}

    end
  end

  describe "valid user" do
    before do
      sign_in user
    end
    describe "GET index" do
      it "when called with subscriber id,  lists all his activities" do
        get :index, {subscriber_id:subscriber}
        expect(assigns(:subscriber_activities)).to eq([SubscriberActivity.find(subscriber_response)])
      end
      it "when called for a message, lists all its subscriber activities" do
        get :index, {message_id:message,channel_id:channel}
        expect(assigns(:subscriber_activities)).to eq([SubscriberActivity.find(subscriber_response)])
      end
      it "when called for a channel, lists all its subscriber activities" do
        get :index, {channel_id:channel}
        expect(assigns(:subscriber_activities)).to match_array([SubscriberActivity.find(subscriber_response),
                    SubscriberActivity.find(other_subscriber_response)])
      end
      it "when called for a channel_group, lists all its subscriber activities" do
        get :index, {channel_group_id:channel_group}
        expect(assigns(:subscriber_activities)).to match_array([SubscriberActivity.find(channel_group_response)])
      end

    end

    describe "GET show" do
      it "assigns the requested message's subscriber activity as @subscriber_activity" do
        get :show, {message_id:message,channel_id:channel,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response))
      end
      it "assigns the requested subscriber's subscriber activity as @subscriber_activity" do
        get :show, {subscriber_id:subscriber,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response))
      end   
      it "assigns the requested channel's subscriber activity as @subscriber_activity" do
        get :show, {channel_id:channel,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response))
      end   
      it "assigns the requested channel_group's subscriber activity as @subscriber_activity" do
        get :show, {channel_group_id:channel_group,:id => channel_group_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(channel_group_response))
      end                  
    end

    describe "GET edit" do
      it "assigns the requested message's subscriber activity as @subscriber_activity" do
        get :edit, {message_id:message,channel_id:channel,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response))
      end
      it "assigns the requested subscriber's subscriber activity as @subscriber_activity" do
        get :edit, {subscriber_id:subscriber,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response))
      end   
      it "assigns the requested channel's subscriber activity as @subscriber_activity" do
        get :edit, {channel_id:channel,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response))
      end   
      it "assigns the requested channel_group's subscriber activity as @subscriber_activity" do
        get :edit, {channel_group_id:channel_group,:id => channel_group_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(channel_group_response))
      end      
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested message's subscriber activity" do
          expect_any_instance_of(SubscriberResponse).to receive(:update_attributes).with({ "caption" => "Sample Caption" })
          put :update, {message_id:message,channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
        end
        it "updates the requested subscriber's subscriber activity" do
          expect_any_instance_of(SubscriberResponse).to receive(:update_attributes).with({ "caption" => "Sample Caption" })
          put :update, {subscriber_id:subscriber,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
        end
        it "updates the requested channel's subscriber activity" do 
          expect_any_instance_of(SubscriberResponse).to receive(:update_attributes).with({ "caption" => "Sample Caption" })
          put :update, {channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
        end
        it "updates the requested channel group's subscriber activity" do
          expect_any_instance_of(SubscriberResponse).to receive(:update_attributes).with({ "caption" => "Sample Caption" })
          put :update, {channel_group_id:channel_group,:id => channel_group_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
        end                        

        it "redirects to the subscriber activity" do
          put :update, {message_id:message,channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"}}
          expect(response).to redirect_to :action => :show, message_id:message,channel_id:channel,id:subscriber_response.to_param
        end
      end

      describe "with invalid params" do
        it "re-renders the 'edit' template" do
          allow_any_instance_of(SubscriberResponse).to receive(:save).and_return(false)
          put :update, {message_id:message,channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"}}
          expect(response).to render_template("edit")
        end
     end
    end
    describe "POST reprocess" do
      it "reprocesses the requested response" do
        expect_any_instance_of(SubscriberResponse).to receive(:process){}
        post :reprocess, {message_id:message,channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
      end
    end
  end
end
