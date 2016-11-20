class SubscribersController < ApplicationController
  include Mixins::SubscriberSearch
  include Mixins::ChannelSearch
  include Mixins::ChannelGroupSearch
  before_filter :load_subscriber
  skip_before_filter :load_subscriber, :only => [:new,:create,:index]
  before_filter :load_user, :only =>[:new,:create,:index]

  def index
    session[:root_page] = subscribers_path
    #@subscribers = @user.subscribers.load
    handle_subscribers_query
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @subscribers }
    end
  end

  def show
    @timeline = Timeline.timeline(params.merge(:user_id => current_user.id))
    @sent_last_24_hours    = @subscriber.delivery_notices.where(created_at: 24.hours.ago..Time.now).count
    @replies_last_24_hours = @subscriber.subscriber_responses.where(created_at: 24.hours.ago..Time.now).count
    @errors_last_24_hours  = @subscriber.delivery_error_notices.where(created_at: 24.hours.ago..Time.now).count
    @actions_last_24_hours = @subscriber.action_notices.where(created_at: 24.hours.ago..Time.now).count

    helper = SubscriberAvailableChannels.new(params.merge(:user_id => current_user.id))
    @available_channels =  helper.channels.delete_if {|x| x.nil? }
    @subscribed_channel_ids = helper.subscribed_channel_ids

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @subscriber }
    end
  end

  def new
    @subscriber = @user.subscribers.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @subscriber }
    end
  end

  def edit
  end

  def create
    @subscriber = @user.subscribers.new(params[:subscriber])

    respond_to do |format|
      if @subscriber.save
        format.html { redirect_to @subscriber, notice: 'Subscriber was successfully created.' }
        format.json { render json: @subscriber, status: :created, location: @subscriber }
      else
        format.html { render action: "new" }
        format.json { render json: @subscriber.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @subscriber.update_attributes(params[:subscriber])
        format.html { redirect_to @subscriber, notice: 'Subscriber was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @subscriber.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @subscriber.destroy

    respond_to do |format|
      format.html { redirect_to subscribers_path }
      format.json { head :no_content }
    end
  end

  private

  def load_user
    authenticate_user!
    @user = current_user
  end

  def load_subscriber
    authenticate_user!
    @user = current_user
    begin
      @subscriber = @user.subscribers.find(params[:id])
      redirect_to(root_url,alert:'Access Denied') unless @subscriber
    rescue
      redirect_to(root_url,alert:'Access Denied')
    end
  end
end
