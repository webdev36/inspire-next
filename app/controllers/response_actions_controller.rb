class ResponseActionsController < ApplicationController
  before_filter :load_message

  def index
    @response_actions = @message.response_actions

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @response_actions }
      format.csv { send_data @message.response_actions.my_csv}

    end
  end


  def new
    @response_action = @message.response_actions.new
    @action = @response_action.build_action if @response_action.action.blank?
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @response_action }
    end
  end  

  def edit
    @response_action = @message.response_actions.find(params[:id])
    @action = @response_action.action
  end

  def create
    @response_action = @message.response_actions.new(params["response_action"])

    respond_to do |format|
      if @response_action.save
        format.html { redirect_to channel_message_response_actions_path(@channel,@message), notice: 'Response Action was successfully created.' }
        format.json { render json: @response_action, status: :created, location: [@channel,@message,@response_action] }
      else
        format.html { render action: "new" }
        format.json { render json: @response_action.errors, status: :unprocessable_entity }
      end
    end
  end  

  def update
    @response_action = @message.response_actions.find(params[:id])

    respond_to do |format|
      if @response_action.update_attributes(params[:response_action])
        format.html { redirect_to [@channel,@message,@response_action], notice: 'Response Action was successfully updated.' }
        format.json { head :no_content }
      else
        Rails.logger.info "**#{@response_action.errors.inspect}"
        format.html { render action: "edit" }
        format.json { render json: @response_action.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @response_action = @message.response_actions.find(params[:id])
    @response_action.destroy

    respond_to do |format|
      format.html { redirect_to channel_message_response_actions_path(@channel,@message) }
      format.json { head :no_content }
    end
  end

  def show
    @response_action = @message.response_actions.find(params[:id])
    @action = @response_action.action
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @response_action }
    end
  end

  def select_import
    session[:import_requester] = request.referer
  end

  def import
    ResponseAction.import(@message,params[:import][:import_from])
    redirect_to session.delete(:import_requester) || request.referer, notice: 'Response Actions imported.'
  end  

  private 

  def load_message
    authenticate_user!
    @user = current_user
    @channel = @user.channels.find(params[:channel_id])
    @messages = @channel.messages
    redirect_to(root_url,alert:'Access Denied') if !@channel 
    @message = @channel.messages.find(params[:message_id])
    redirect_to(root_url,alert:'Access Denied') if !@message 
    @channels = current_user.channels
    rescue
      redirect_to(root_url,alert:'Access Denied')
  end
end