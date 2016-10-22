class ChannelsController < ApplicationController
  before_action :load_channel
  skip_before_action :load_channel, only: %i(
      new create index add_subscriber remove_subscriber
    )
  before_action :load_user, only: %i(new create index)
  before_action :load_subscriber, only: %i(add_subscriber remove_subscriber)

  decorates_assigned :messages

  def index
    session[:root_page] = channels_path
    @channels = @user.channels
      .where(channel_group_id: nil)
      .order(created_at: :desc)
      .page(params[:channels_page])
      .per_page(10)
    @channel_groups = @user.channel_groups
      .order(created_at: :desc)
      .page(params[:channel_groups_page])
      .per_page(10)

    respond_to do |format|
      format.html
      format.json { render json: @channels }
    end
  end

  def show
    if @channel
      @subscribers = @channel.subscribers.includes(:subscriptions)
        .order("subscriptions.created_at")
        .page(params[:subscribers_page])
        .per_page(10)

      @messages = @channel.messages

      @message_counts_by_type = { "All" => @messages.size }
      %w(ActionMessage PollMessage ResponseMessage SimpleMessage TagMessage).each do |message_type|
        count = @messages.where(type: message_type).size
        @message_counts_by_type[message_type] = count if count > 0
      end

      if params[:message_type].present? && params[:message_type] != "All"
        @messages = @messages.where(type: params[:message_type])
      end

      @messages = if @channel.sequenced?
        @messages.order(:seq_no)
      elsif @channel.individual_messages_have_schedule?
        @messages.order(:created_at)
      else
        @messages.order(created_at: :desc)
      end

      @messages = @messages
        .sort { |x, y| x.target_time <=> y.target_time }
        .paginate(page: params[:messages_page], per_page: 10)
    end

    respond_to do |format|
      format.html
      format.json { render json: @channel }
    end
  end

  def new
    @channel = @user.channels.new
    if params["channel_group_id"].present?
      ch_group = @user.channel_groups.find(params["channel_group_id"])
      @channel.channel_group = ch_group if ch_group
    end

    respond_to do |format|
      format.html
      format.json { render json: @channel }
    end
  end

  def edit; end

  def create
    @channel = @user.channels.new(params[:channel])
    respond_to do |format|
      if @channel.save
        format.html { redirect_to [@channel], notice: 'Channel was successfully created.' }
        format.json { render json: @channel, status: :created, location: [@channel] }
      else
        format.html { render action: "new", alert: @channel.errors.full_messages.join(", and ")}
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
    @subscribed_subscribers = @channel.subscribers
      .page(params[:subscribed_subscribers_page])
      .per_page(10)

    @unsubscribed_subscribers = if subs_subs_ids.size == 0
      @user.subscribers
        .page(params[:unsubscribed_subscribers_page])
        .per_page(10)
    else
      @user.subscribers
        .where("id not in (?)", subs_subs_ids)
        .page(params[:unsubscribed_subscribers_page])
        .per_page(10)
    end

    respond_to do |format|
      format.html
      format.json { render json: @channel }
    end
  end

  def add_subscriber
    already_subscribed = @channel.subscribers.where(id: @subscriber.id).first
    notice = "Subscriber already added a member of the channel group. No changes made."

    unless already_subscribed
      if @channel.subscribers.push @subscriber
        notice = "Subscriber added to channel."
      else
        error = "Subscriber is already a member of a channel in the channel group. Cannot add."
      end
    end

    respond_to do |format|
      format.html { redirect_to list_subscribers_channel_path(id: @channel), notice: notice }
      format.json { render json: @channel.subscribers, location: [@channel] }
    end
  end

  def remove_subscriber
    already_subscribed = @channel.subscribers.where(id: @subscriber.id).first
    notice = "Subscriber not currently subscribed to this channel. No changes done."

    if already_subscribed
      @channel.subscribers.destroy @subscriber
      notice = "Subscriber removed from channel."
    end

    respond_to do |format|
      format.html { redirect_to list_subscribers_channel_path(id: @channel), notice: notice }
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

  def delete_all_messages
    @channel.messages.delete_all
    redirect_to :back, notice: "All messages were deleted."
  end

  private

    def channel_params
      params.require(:channel)
        .permit(
          :description, :name, :type, :keyword, :tparty_keyword, :schedule,
          :channel_group_id, :one_word, :suffix, :moderator_emails,
          :real_time_update, :relative_schedule, :send_only_once, :active,
          :allow_mo_subscription, :mo_subscription_deadline
        )
    end

    def load_user
      authenticate_user!
      @user = current_user
    end

    def load_channel
      authenticate_user!
      @user = current_user
      @channel = @user.channels.find(params[:id])
      redirect_to root_url, alert: "Access Denied" unless @channel
    rescue ActiveRecord::RecordNotFound
      redirect_to root_url, alert: "Access Denied"
    end

    def load_subscriber
      authenticate_user!
      @user = current_user
      @channel = @user.channels.find(params[:channel_id])
      redirect_to root_url, alert: "Access Denied" unless @channel
      @subscriber = @user.subscribers.find(params[:id])
      redirect_to root_url, alert: "Access Denied" unless @subscriber
    rescue ActiveRecord::RecordNotFound
      redirect_to root_url, alert: "Access Denied"
    end
end
