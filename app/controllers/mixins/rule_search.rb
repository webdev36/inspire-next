require 'active_support/concern'

module Mixins
  module RuleSearch
    extend ActiveSupport::Concern
    def handle_rule_query
      @rules = @user.rules
                    .order(created_at: :desc)
                    .page(params[:rules_page])
                    .per_page(10)
      @rules = @rules.search(params[:rules_search]) if params[:rules_search]
    end
  end
end
