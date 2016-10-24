class SubscriberActivitiesController < ApplicationController
  include SubscriberActivitiesHelper
  # before_filter      :load_activity
  before_filter      :load_activity,   except: [:index]
  before_filter      :load_activities, only: [:index]

  def index
    if params[:unprocessed] == 'true' && @subscriber_activities
      @subscriber_activities = @subscriber_activities.unprocessed
      @unprocessed = true
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @subscriber_activities }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @subscriber_activity }
    end
  end

  def edit

  end

  def update
    respond_to do |format|
      if @subscriber_activity.update_attributes(params[:subscriber_activity])
        format.html { redirect_to sa_path(@subscriber_activity).merge({action:'show'}), notice: 'Subscriber Activity was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @subscriber_activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def reprocess
    respond_to do |format|
      if @subscriber_activity.process
        format.html { redirect_to sa_path(@subscriber_activity).merge({action:'show'}), notice: 'Reprocess successful' }
        format.json { head :no_content }
      else
        format.html { redirect_to sa_path(@subscriber_activity).merge({action:'show'}), notice: 'Reprocess failed' }
        format.json { render json: @subscriber_activity.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def common_authentication_and_fetch
    authenticate_user!
    @user = current_user
    @subscriber = @user.subscribers.find(params[:subscriber_id]) rescue nil
    @channel = @user.channels.find(params[:channel_id]) rescue nil
    @channel_group = @user.channel_groups.find(params[:channel_group_id]) rescue nil
    @message = @channel.messages.find(params[:message_id]) rescue nil
    @type = params[:type]
    @klass = case(@type)
    when 'SubscriberResponse'
      SubscriberResponse
    when 'DeliveryNotice'
      DeliveryNotice
    else
      SubscriberActivity
    end
  end

  def load_activity
    common_authentication_and_fetch
    redirect_to(root_url,alert:'Access Denied') if @subscriber.nil? && @message.nil? && @channel.nil? && @channel_group.nil?
    if @subscriber
      @criteria = 'Subscriber'
      @target = @subscriber
      @subscriber_activity = @klass.of_subscriber(@subscriber).find(params[:id])
    elsif @message
      @criteria = 'Message'
      @target = @message
      @subscriber_activity = @klass.for_message(@message).find(params[:id])
    elsif @channel
      @criteria = 'Channel'
      @target = @channel
      @subscriber_activity = @klass.for_channel(@channel).find(params[:id])
    elsif @channel_group
      @criteria = 'ChannelGroup'
      @target = @channel_group
      @subscriber_activity = @klass.for_channel_group(@channel_group).find(params[:id])
    end
  rescue
    redirect_to(root_url,alert:'Access Denied')
  end

  def load_activities
    common_authentication_and_fetch
    redirect_to(root_url,alert:'Access Denied') if @subscriber.nil? && @message.nil? && @channel.nil? && @channel_group.nil?
    if @subscriber
      @criteria = 'Subscriber'
      @target = @subscriber
      @subscriber_activities = @klass.of_subscriber(@subscriber).order('created_at DESC').page(params[:page]).per_page(10)
    elsif @message
      @criteria = 'Message'
      @target = @message
      @subscriber_activities = @klass.for_message(@message).order('created_at DESC').page(params[:page]).per_page(10)
    elsif @channel
      @criteria = 'Channel'
      @target = @channel
      @subscriber_activities = @klass.for_channel(@channel).order('created_at DESC').page(params[:page]).per_page(10)
    elsif @channel_group
      @criteria = 'ChannelGroup'
      @target = @channel_group
      @subscriber_activities = @klass.for_channel_group_and_its_channels(@channel_group).order('created_at DESC').page(params[:page]).per_page(10)
    end
  rescue
      redirect_to(root_url,alert:'Access Denied')
  end
end
