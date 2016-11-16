require 'active_support/concern'

module Mixins
  module MessageSearch
    extend ActiveSupport::Concern
    def handle_message_query
      @messages = @channel.messages.order(created_at: :desc)
                           .page(params[:messages_page])
                           .per_page(10)
      @messages = @messages.search(params[:message_search]) if params[:message_search]
    end
  end
end
