module Admin
  class ChannelsController < ApplicationController
    before_action :load_user

    def index
      @channels = Channel.all
      @channel_groups = ChannelGroup.all
      respond_to do |format|
        format.html
        format.json { render json: @channels }
      end
    end

  private

    def load_user
      authenticate_user!
      @user = current_user
    end

  end
end
