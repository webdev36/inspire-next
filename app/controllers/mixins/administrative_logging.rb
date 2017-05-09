require 'active_support/concern'

module Mixins
  module AdministrativeLogging
    extend ActiveSupport::Concern

    def log_user_activity(caption, additional_fields = {})
      an = ActionNotice.new
      an.caption = caption
      an.user_id = current_user.id
      additional_fields.keys.each do |key|
        an[key] = additional_fields[key]
      end
      an.save
      an
    end
  end
end
