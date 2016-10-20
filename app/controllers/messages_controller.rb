require 'will_paginate/array'
class MessagesController < ApplicationController
  before_filter :load_channel
  def index
    @messages = @channel.messages

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @messages }
      format.csv { send_data Message.where(channel_id:@channel.id).my_csv}
      format.xls { send_data Message.where(channel_id:@channel.id).my_csv(col_sep:"\t")}
    end
  end

  def show
    @message = @channel.messages.find(params[:id])
    if @message.requires_user_response?
      @grouped_responses = @message.grouped_responses || []
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @message }
    end
  end

  def new
    @message = @channel.messages.new
    @action = @message.build_action
    3.times { @message.message_options.build }
    # @message.response_actions.build if @message.response_actions.blank?
    @channels = current_user.channels

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @message }
    end
  end

  def edit
    @message = @channel.messages.find(params[:id])
    @action = @message.action
    @channels = current_user.channels
    #@message.response_actions.build if @message.response_actions.blank?
  end

  def create
    params_copy = Marshal.load(Marshal.dump(params))
    params_copy["message"].delete("action_attributes") if params[:message][:type] != 'ActionMessage'
    @message = @channel.messages.new(params_copy["message"])
    @channels = current_user.channels

    respond_to do |format|
      if @message.save
        format.html { redirect_to [@channel,@message], notice: 'Message was successfully created.' }
        format.json { render json: @message, status: :created, location: [@channel,@message] }
      else
        format.html { render action: "new" }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @message = @channel.messages.find(params[:id])

    respond_to do |format|
      if @message.update_attributes(params[:message])
        format.html { redirect_to [@channel,@message], notice: 'Message was successfully updated.' }
        format.json { head :no_content }
      else
        Rails.logger.info "**#{@message.errors.inspect}"
        format.html { render action: "edit" }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @message = @channel.messages.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.html { redirect_to channel_url(@channel),:page=>params[:page_no] }
      format.json { head :no_content }
    end
  end


  def broadcast
    message = @channel.messages.find(params[:id])
    message.broadcast
    respond_to do |format|
      format.html { redirect_to [@channel,@message], notice: 'Message was queued for broadcast.' }
      format.json { head :no_content }
    end
  end

  def move_up
    message = @channel.messages.find(params[:id])
    message.move_up
    respond_to do |format|
      format.html { redirect_to [@channel,@message] }
      format.json { head :no_content }
    end
  end

  def move_down
    message = @channel.messages.find(params[:id])
    message.move_down
    respond_to do |format|
      format.html { redirect_to [@channel,@message] }
      format.json { head :no_content }
    end
  end

  def responses
    @message = @channel.messages.find(params[:id])
    grouped_responses = @message.grouped_responses || []
    @grouped_response= grouped_responses.find {|gr|
      gr[:message_content] == params[:with_content] }
    @response = params[:with_content]
    @subscriber_responses = @grouped_response[:subscriber_responses]
    @subscriber_responses = @subscriber_responses.paginate(page:params[:page],per_page:10)
  end

  def select_import
    session[:import_requester] = request.referer
  end

  def import
    Message.import(@channel,params[:import][:import_from])
    redirect_to session.delete(:import_requester) || request.referer, notice: 'Messages imported.'
  end

  private

  def load_channel
    authenticate_user!
    @user = current_user
    @channel = @user.channels.find(params[:channel_id])
    redirect_to(root_url,alert:'Access Denied') if !@channel
    rescue
      redirect_to(root_url,alert:'Access Denied')
  end
end
