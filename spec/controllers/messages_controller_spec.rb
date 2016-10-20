require 'spec_helper'
describe MessagesController do
  let(:user){create(:user)}
  let(:channel) {create(:channel,user:user)}
  let(:valid_attributes) { attributes_for(:message) }
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end
  
  describe "guest user" do
    it "is redirected to signup form always and not allowed to alter db" do
      message = channel.messages.create! valid_attributes

      get :index, {channel_id:channel}
      expect(response).to redirect_to new_user_session_path

      get :select_import, {channel_id:channel}
      expect(response).to redirect_to new_user_session_path

      get :import, {channel_id:channel}
      expect(response).to redirect_to new_user_session_path            

      get :show, {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to new_user_session_path

      get :responses, {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to new_user_session_path

      get :new, {channel_id:channel}
      expect(response).to redirect_to new_user_session_path

      get :edit, {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to new_user_session_path

      expect {
            post :create, {channel_id:channel,:message => valid_attributes}
          }.to_not change(Message, :count).by(1)
      
      Message.any_instance.should_not_receive(:update_attributes)
      put :update, {channel_id:channel,:id => message.to_param, :message => { "title" => "MyText" }}

      expect {
          delete :destroy, {channel_id:channel,:id => message.to_param}
        }.to_not change(Message, :count).by(-1)
    end
  end

  describe "one user" do
    it "is not be able to access other user's messages" do
      message = channel.messages.create! valid_attributes
      another_user = create(:user)
      sign_in another_user

      get :select_import, {channel_id:channel}
      expect(response).to redirect_to root_url

      post :import, {channel_id:channel}
      expect(response).to redirect_to root_url

      get :index, {channel_id:channel}
      expect(response).to redirect_to root_url      

      get :show, {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to root_url

      get :responses, {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to root_url

      get :new, {channel_id:channel}
      expect(response).to redirect_to root_url

      get :edit, {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to root_url

      expect {
            post :create, {channel_id:channel,:message => valid_attributes}
          }.to_not change(Message, :count).by(1)
      
      Message.any_instance.should_not_receive(:update_attributes)
      put :update, {channel_id:channel,:id => message.to_param, :message => { "title" => "MyText" }}

      expect {
          delete :destroy, {channel_id:channel,:id => message.to_param}
        }.to_not change(Message, :count).by(-1)

    end
  end

  describe "valid user" do
    before do
      sign_in user
    end
    describe "GET index" do
      it "assigns all messages as @messages" do
        message = channel.messages.create! valid_attributes
        get :index, {user_id:user,channel_id:channel}
        assigns(:messages).should eq([Message.find(message)])
      end
    end

    describe "GET show" do
      it "assigns the requested message as @message" do
        message = channel.messages.create! valid_attributes
        get :show, {channel_id:channel,:id => message.to_param}
        assigns(:message).should eq(Message.find(message))
      end
    end

    describe "GET responses" do
      it "assigns the requested message as @message" do
        message = channel.messages.create! valid_attributes
        get :show, {channel_id:channel,:id => message.to_param}
        assigns(:message).should eq(Message.find(message))
      end
    end    

    describe "GET new" do
      it "assigns a new message as @message" do
        get :new, {channel_id:channel}
        assigns(:message).should be_a_new(Message)
      end
    end

    describe "GET edit" do
      it "assigns the requested message as @message" do
        message = channel.messages.create! valid_attributes
        get :edit, {channel_id:channel,:id => message.to_param}
        assigns(:message).should eq(Message.find(message))
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Message" do
          expect {
            post :create, {channel_id:channel,:message => valid_attributes}
          }.to change(Message, :count).by(1)
        end

        it "assigns a newly created message as @message" do
          post :create, {channel_id:channel,:message => valid_attributes}
          assigns(:message).should be_a(Message)
          assigns(:message).should be_persisted
        end

        it "redirects to the created message" do
          post :create, {channel_id:channel,:message => valid_attributes}
          response.should redirect_to([channel,Message.last])
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved message as @message" do
          # Trigger the behavior that occurs when invalid params are submitted
          Message.any_instance.stub(:save).and_return(false)
          post :create, {channel_id:channel,:message => { "title" => "invalid value" }}
          assigns(:message).should be_a_new(Message)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          Message.any_instance.stub(:save).and_return(false)
          post :create, {channel_id:channel,:message => { "title" => "invalid value" }}
          response.should render_template("new")
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested message" do
          message = channel.messages.create! valid_attributes
          # Assuming there are no other messages in the database, this
          # specifies that the Message created on the previous line
          # receives the :update_attributes message with whatever params are
          # submitted in the request.
          Message.any_instance.should_receive(:update_attributes).with({ "title" => "MyText" })
          put :update, {channel_id:channel,:id => message.to_param, :message => { "title" => "MyText" }}
        end

        it "assigns the requested message as @message" do
          message = channel.messages.create! valid_attributes
          put :update, {channel_id:channel,:id => message.to_param, :message => valid_attributes}
          assigns(:message).should eq(Message.find(message))
        end

        it "redirects to the message" do
          message = channel.messages.create! valid_attributes
          put :update, {channel_id:channel,:id => message.to_param, :message => valid_attributes}
          response.should redirect_to([channel,message])
        end
      end

      describe "with invalid params" do
        it "assigns the message as @message" do
          message = channel.messages.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          Message.any_instance.stub(:save).and_return(false)
          put :update, {channel_id:channel,:id => message.to_param, :message => { "title" => "invalid value" }}
          assigns(:message).should eq(Message.find(message))
        end

        it "re-renders the 'edit' template" do
          message = channel.messages.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          Message.any_instance.stub(:save).and_return(false)
          put :update, {channel_id:channel,:id => message.to_param, :message => { "title" => "invalid value" }}
          response.should render_template("edit")
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested message" do
        message = channel.messages.create! valid_attributes
        expect {
          delete :destroy, {channel_id:channel,id: message.to_param}
        }.to change(Message, :count).by(-1)
      end

      it "redirects to the channel show" do
        message = channel.messages.create! valid_attributes
        delete :destroy, {channel_id:channel,id: message.to_param}
        response.should redirect_to(channel_url(channel))
      end
    end    

    describe "POST broadcast" do
      it "calls broadcast for message for all subscribers" do
        message = create(:message,channel:channel)
        subscribers = (0..2).map {create(:subscriber,user:user)}
        subscribers.each do |subs|
          channel.subscribers << subs
        end
        sub_nos = subscribers.map {|s| s.phone_number}
        Message.any_instance.should_receive(:broadcast) do |phone_nos|
          phone_nos =~ sub_nos
        end
        post :broadcast, {channel_id:channel, id:message.to_param}
      end
    end

    describe "GET select_import" do
      it "assigns @channel with the channel" do
        get :select_import, {user_id:user,channel_id:channel}
        assigns(:channel).should == Channel.find(channel)        
      end
    end



  end


end
