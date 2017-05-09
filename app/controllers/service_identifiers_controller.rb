class ServiceIdentifiersController < ApplicationController
  before_action :load_user, only: %i(index)

  def index
    @service_identifiers = Set.new
    @user.channels.each do |channel|
      @service_identifiers << channel.tparty_keyword
    end
    @user.channel_groups.each do |channel_group|
      @service_identifiers << channel_group.tparty_keyword
    end
  end

  private

    def load_user
      authenticate_user!
      @user = current_user
    end
end
