require 'active_support/concern'

module Mixins
  module SubscriberSearch
    extend ActiveSupport::Concern

    def subscribers_page
      params[:subscribers_page] || 1
    end

    def handle_subscribers_query
      if @channel
        @subscribers = @channel.subscribers.includes(:subscriptions)
                            .order("subscriptions.created_at DESC")
      elsif @channel_group
        channel_ids = @channel_group.channels.pluck(:id)
        @subscribers = Subscriber.includes(:subscriptions)
                                 .where("subscriptions.channel_id in (?)", channel_ids)
                                 .order("subscriptions.created_at DESC")
      else
        @subscribers = @user.subscribers
                            .order(created_at: :desc)
      end
      @subscribers = @subscribers.page(subscribers_page)
                                 .per_page(10)
      @subscribers = @subscribers.search(params[:subscribers_search]) if params[:subscribers_search]
    end
  end
end
