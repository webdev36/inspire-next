class UsersController < ApplicationController
  
  before_filter :load_user, :only => [:show]
  
  def show
    session[:root_page] = user_path(@user)
    @channels = @user.channels.where(channel_group_id:nil).page(params[:channels_page]).per_page(10)
    @channel_groups = @user.channel_groups.page(params[:channel_groups_page]).per_page(10)
    @subscribers = @user.subscribers.page(params[:subscribers_page]).per_page(10)
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