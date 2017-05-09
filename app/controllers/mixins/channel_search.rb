require 'active_support/concern'

module Mixins
  module ChannelSearch
    extend ActiveSupport::Concern
    def handle_channel_query
      if @channel_group
        @channels = @channel_group.channels
      else
        @channels = @user.channels.not_in_any_group
      end
      @channels = @channels.order(created_at: :desc)
                           .page(params[:channels_page])
                           .per_page(10)
      @channels = @channels.search(params[:channel_search]) if params[:channel_search]
    end
  end
end
