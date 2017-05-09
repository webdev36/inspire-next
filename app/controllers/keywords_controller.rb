class KeywordsController < ApplicationController
  before_action :load_user, only: %i(index)

  def index
    @channels = []
    @user.channel_groups.each do |group|
      group.channels.each do |channel|
        @channels << channel
      end
    end
    @user.channels.each do |channel|
      @channels << channel unless @channels.include?(channel)
    end
  end

  private

    def load_user
      authenticate_user!
      @user = current_user
    end
end
