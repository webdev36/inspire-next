class ResponseActionsController < ApplicationController
  before_filter :load_user
  before_filter :load_message
  before_action :load_channel
  before_action :load_message
  before_action :load_channels_and_messages
  before_action :load_to_channel_options, only: %i(edit new create update)

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
    binding.pry
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
    @response_action = ResponseActionFactory
      .new(response_action_params, params, response_action: nil, message: @message)
      .response_action

    respond_to do |format|
      if @response_action.save
        format.html { redirect_to channel_message_response_actions_path(@channel, @message), notice: 'Response Action was successfully created.' }
        format.json { render json: @response_action, status: :created, location: [@channel,@message,@response_action] }
      else
        Rails.logger.info "**#{@response_action.errors.inspect}"
        format.html { render action: "new", alert: @response_action.errors.full_messages.join(", ") }
        format.json { render json: @response_action.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @response_action = @message.response_actions.find(params[:id])
    @response_action = ResponseActionFactory
      .new(response_action_params, params, response_action: @response_action, message: @message)
      .response_action

    binding.pry

    respond_to do |format|
      if @response_action.update_attributes(params[:response_action])
        format.html { redirect_to channel_message_response_actions_path(@channel, @message), notice: 'Response Action was successfully updated.' }
        format.json { head :no_content }
      else
        Rails.logger.info "**#{@response_action.errors.inspect}"
        format.html { render action: "edit", alert: @response_action.errors.full_messages.join(", ") }
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

    def response_action_params
      params.require(:response_action)
        .permit(
          :response_text,
          action_attributes: %i(id type as_text to_channel message_to_send resume_from_last_state),
        )
    end

    def load_user
      authenticate_user!
      @user ||= current_user
    end

    def load_channel
      @channel = @user.channels.find(params[:channel_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_url, alert: "Access Denied"
    end

    def load_message
      @message = @channel.messages.find(params[:message_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_url, alert: "Access Denied"
    end

    def load_channels_and_messages
      @channels = @user.channels
      @messages = @channel.messages
    end

    def load_to_channel_options
      @to_channel_options = { in_group: {}, out_group: [] }
      @user.channels.each do |channel|
        if channel.channel_group_id
          @to_channel_options[:in_group][channel.channel_group_id] ||= []
          @to_channel_options[:in_group][channel.channel_group_id] << [channel.name, channel.id]
        else
          @to_channel_options[:out_group] << [channel.name, channel.id]
        end
      end
    end

end
