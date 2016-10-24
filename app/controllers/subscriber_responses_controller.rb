class SubscriberResponsesController < ApplicationController
  # before_filter      :load_activity
  before_filter      :common_authentication_and_fetch

  def index
    @subscriber_responses = @subscriber.subscriber_responses
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @subscriber_responses }
    end
  end

  private

  def common_authentication_and_fetch
    authenticate_user!
    @user = current_user
    @subscriber = @user.subscribers.find(params[:subscriber_id]) rescue nil
  end

end
