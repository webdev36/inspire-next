class UsersController < ApplicationController
  include Mixins::SubscriberSearch
  include Mixins::ChannelSearch
  include Mixins::ChannelGroupSearch

  before_filter :load_user, :only => [:show]

  def show
    session[:root_page] = user_path(@user)
    handle_channel_group_query
    handle_channel_query
    handle_subscribers_query
    respond_to do |format|
      format.html
      format.json { render json: [@channels,@subscribers] }
    end

  end

  private

  def load_user
    authenticate_user!
    @user = User.find(params[:id])
    redirect_to(root_url,alert:'Access Denied') unless @user == current_user
  end
end
