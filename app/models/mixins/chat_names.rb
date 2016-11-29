module Mixins
  module ChatNames
    extend ActiveSupport::Concern

    def chatname
      @chatname ||= begin
        unless self.chat_name
          generate_chat_name! if chat_name.blank?
          self.chat_name
        end
        self.chat_name
      end
    end

    def generate_chat_name!
      new_name =  Haikunator.haikunate(0)
      self.chat_name = new_name
      self.save
      new_name
    end

  end
end
