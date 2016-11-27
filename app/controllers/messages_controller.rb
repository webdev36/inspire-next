require 'will_paginate/array'

class MessagesController < ApplicationController
  include Mixins::AdministrativeLogging
  before_filter :load_channel
  before_filter  :build_channel_group_map, only: %i(new show)
  before_action :load_to_channel_options, only: %i(new edit show create update)
  before_action :load_message, only: %i(show)

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
  end

  def create
    @message = MessageFactory.new(params.to_hash, @channel).message
    @channels = current_user.channels

    respond_to do |format|
      if @message.save
        log_user_activity("Created new message #{@message.id}-#{@message.caption}")
        format.html { redirect_to [@channel], notice: 'Message was successfully created.' }
        format.json { render json: @message, status: :created, location: [@channel,@message] }
      else
        format.html { render action: "new", alert: @message.errors.full_messages.join(", ") }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    found_message = @channel.messages.find(params[:id])
    @message = MessageFactory.new(params, @channel, found_message).message
    @channels = current_user.channels
    respond_to do |format|
      if @message.save
        log_user_activity("Updated message #{@message.id}-#{@message.caption}")
        format.html { redirect_to [@channel, @message], notice: 'Message was successfully updated.' }
        format.json { head :no_content }
      else
        Rails.logger.error "error=error_updating_message message_id=#{@message.try(:id)} message='#{@message.errors.inspect}'"
        format.html { render action: "edit" }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @message = @channel.messages.find(params[:id])
    @message.destroy
    log_user_activity("Deleted message #{@message.id}-#{@message.caption}")

    respond_to do |format|
      format.html { redirect_to channel_url(@channel),:page=>params[:page_no] }
      format.json { head :no_content }
    end
  end

  def broadcast
    message = @channel.messages.find(params[:id])
    message.broadcast
    log_user_activity("Broadcast message #{message.id}-#{message.caption}")
    respond_to do |format|
      format.html { redirect_to [@channel,@message], notice: 'Message was queued for broadcast.' }
      format.json { head :no_content }
    end
  end

  def move_up
    message = @channel.messages.find(params[:id])
    message.move_up
    log_user_activity("Moved up message #{message.id}-#{message.caption}")
    respond_to do |format|
      format.html { redirect_to [@channel,@message] }
      format.json { head :no_content }
    end
  end

  def move_down
    message = @channel.messages.find(params[:id])
    message.move_down
    log_user_activity("Moved down message #{message.id}-#{message.caption}")
    respond_to do |format|
      format.html { redirect_to [@channel,@message] }
      format.json { head :no_content }
    end
  end

  def responses
    @message = @channel.messages.find(params[:id])
    g_resps = @message.grouped_responses || []
    @grouped_response = g_resps.find { |e| e[:message_content] == params[:with_content] }
    @subscriber_responses = @grouped_response[:subscriber_responses].paginate(
      page: params[:page],
      per_page: 10,
    )
    @response = params[:with_content]
  end

  def select_import
    session[:import_requester] = request.referer
  end

  def import
    begin
      file = params[:import][:import_from]
      helper = ImportChannel.new(@channel, file)
      if helper.import
        log_user_activity("Imported messages from #{file.to_s} to channel #{@channel.id}-#{@channel.name}")
        notice_message = "Your channel messages were imported."
        redirect_to request.referer, notice: notice_message
      else
        log_user_activity("Error importing messages from #{file.to_s} to channel #{@channel.id}-#{@channel.name}")
        notice_message = "There was a problem importing your messages."
        redirect_to request.referer, error: resp[:message]
      end
    rescue => e
      puts "#{e.inspect}"
      redirect_to request.referer, notice: "There was a problem uploading the file. Check your file and try again."
    end
  end

  def update_seq_no
    @message = @channel.messages.find(message_params[:id])
    @message.set_seq_position(message_params[:seq_no_position])
    @message.save
    render nothing: true
  end

  private

    def message_params(p = params)
      Array(p.try(:[], "message").try(:[], "message_options_attributes").try(:keys)).each do |key|
        p.try(:[], "message").try(:[], "message_options_attributes").try(:[], key).delete("_destroy")
      end

      if p.try(:[], "message").try(:[], "action_attributes")
        p.try(:[], "message").try(:[], "action_attributes").try(:delete, "id")
      end

      p.require(:message)
        .permit(:title, :caption, :type, :content, :next_send_time,
                :reminder_message_text, :reminder_delay,
                :repeat_reminder_message_text, :repeat_reminder_delay,
                :number_of_repeat_reminders, :action_attributes, :schedule,
                :relative_schedule_type, :relative_schedule_number,
                :relative_schedule_day, :relative_schedule_hour, :id,
                :relative_schedule_minute, :active, :_destroy, :seq_no_position,
                :message_options_attributes, :recurring_schedule,
                message_options_attributes: %i(key message_id value),
                action_attributes: %i(
                  type as_text to_channel message_to_send resume_from_last_state
                ))
    rescue => e
      raise e
    end

    def build_channel_group_map
      @channel_group_id_map = {}
      current_user.channel_groups.each do |channel_group|
        @channel_group_id_map[channel_group.id] = channel_group.name
      end
    end

    def load_channel
      authenticate_user!
      @user = current_user
      @channel = @user.channels.find(params[:channel_id])
      redirect_to(root_url,alert:'Access Denied') if !@channel
      rescue
        redirect_to(root_url,alert:'Access Denied')
    end

    def load_to_channel_options
      @to_channel_options = { in_group: {}, out_group: [] }
      current_user.channels.each do |channel|
        if channel.channel_group_id
          @to_channel_options[:in_group][channel.channel_group_id] ||= []
          @to_channel_options[:in_group][channel.channel_group_id] << [channel.name, channel.id]
        else
          @to_channel_options[:out_group] << [channel.name, channel.id]
        end
      end
    end

    def load_message
      @message = @channel.messages.find(params[:id])
      if @message.requires_user_response?
        @grouped_responses = @message.grouped_responses || []
      end
    end

end
