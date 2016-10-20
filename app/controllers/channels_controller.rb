class ChannelsController < ApplicationController

  before_filter :load_channel
  skip_before_filter :load_channel, :only => [:new,:create,:index,:add_subscriber,:remove_subscriber]
  before_filter :load_user, :only =>[:new,:create,:index]
  before_filter :load_subscriber, :only =>[:add_subscriber,:remove_subscriber]

  def index
    session[:root_page] = channels_path
    @channels = @user.channels.where(channel_group_id:nil).order('created_at DESC').page(params[:channels_page]).per_page(10)
    @channel_groups = @user.channel_groups.order('created_at DESC').page(params[:channel_groups_page]).per_page(10)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @channels }
    end
  end

  def show
    @subscribers = @channel.subscribers.page(params[:subscribers_page]).per_page(10) if @channel

    if @channel.sequenced?
      @messages = @channel.messages.order('seq_no ASC').page(params[:messages_page]).per_page(10) if @channel
    elsif @channel.individual_messages_have_schedule?
      @messages = @channel.messages.order('created_at ASC').page(params[:messages_page]).per_page(10) if @channel
    else
      @messages = @channel.messages.order('created_at DESC').page(params[:messages_page]).per_page(10) if @channel
    end


    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @channel }
    end
  end

  def new
    @channel = @user.channels.new
    if !params["channel_group_id"].blank?
      ch_group = @user.channel_groups.find(params["channel_group_id"])
      if ch_group
        @channel.channel_group = ch_group
      end
    end
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @channel }
    end
  end

  def edit
  end

  def create
    @channel = @user.channels.new(params[:channel])
    respond_to do |format|
      if @channel.save
        format.html { redirect_to [@channel], notice: 'Channel was successfully created.' }
        format.json { render json: @channel, status: :created, location: [@channel] }
      else
        format.html { render action: "new" }
        format.json { render json: @channel.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @channel.update_attributes(params[:channel])
        format.html { redirect_to @channel, notice: 'Channel was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @channel.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @channel.destroy

    respond_to do |format|
      format.html { redirect_to user_url(@user) }
      format.json { head :no_content }
    end
  end

  def list_subscribers
    subscribed_subscribers = @channel.subscribers
    subs_subs_ids = subscribed_subscribers.map(&:id)
    @subscribed_subscribers = @channel.subscribers.page(params[:subscribed_subscribers_page]).per_page(10)
    if subs_subs_ids.length==0
      @unsubscribed_subscribers = @user.subscribers.page(params[:unsubscribed_subscribers_page]).per_page(10)
    else
      @unsubscribed_subscribers = @user.subscribers.where('id not in (?)',subs_subs_ids).page(params[:unsubscribed_subscribers_page]).per_page(10)
    end

    respond_to do |format|
     format.html
     format.json { render json: @channel }
    end
  end

  def add_subscriber
    already_subscribed = @channel.subscribers.where(id:@subscriber.id).first
    notice = 'Subscriber already added a member of the channel group. No changes made'
    unless already_subscribed
      if @channel.subscribers << @subscriber
        notice = 'Subscriber added to channel'
      else
        error = "Subscriber is already a member of a channel in the channel group. Cannot add."
      end
    end
    respond_to do |format|
      format.html { redirect_to list_subscribers_channel_path(id:@channel), notice: notice }
      format.json { render json: @channel.subscribers, location: [@channel] }
    end
  end

  def remove_subscriber
    already_subscribed = @channel.subscribers.where(id:@subscriber.id).first
    notice = 'Subscriber not currently subscribed to this channel. No changes done'
    if already_subscribed
      @channel.subscribers.delete @subscriber
      notice='Subscriber removed from channel'
    end
    respond_to do |format|
      format.html { redirect_to list_subscribers_channel_path(id:@channel), notice: notice }
      format.json { render json: @channel.subscribers, location: [@channel] }
    end
  end

  def messages_report
    respond_to do |format|
      format.csv {send_data @channel.messages_report}
    end
  end

  def rollback_notification
    error = "Subscriber not added, because the are already a subscribed to a channel in the group."
  end


  private
    def load_user
      authenticate_user!
      @user = current_user
    end

    def load_channel
      authenticate_user!
      @user = current_user
      @channel = @user.channels.find(params[:id])
      redirect_to(root_url,alert:'Access Denied') unless @channel
    rescue
        redirect_to(root_url,alert:'Access Denied')
    end

    def load_subscriber
      authenticate_user!
      @user = current_user
      @channel = @user.channels.find(params[:channel_id])
      redirect_to(root_url,alert:'Access Denied') unless @channel
      @subscriber = @user.subscribers.find(params[:id])
      redirect_to(root_url,alert:'Access Denied') unless @subscriber
    rescue
      redirect_to(root_url,alert:'Access Denied')
    end
end
