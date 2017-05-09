require 'active_support/concern'

module Mixins
  module ChannelGroupSearch
    extend ActiveSupport::Concern
    def handle_channel_group_query
      @channel_groups = @user.channel_groups
                             .order(created_at: :desc)
                             .page(params[:channel_groups_page])
                             .per_page(10)
      @channel_groups = @channel_groups.search(params[:channel_group_search]) if params[:channel_group_search]
    end
  end
end
