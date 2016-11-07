# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#

class SendMessageAction < Action
  include Rails.application.routes.url_helpers
  include ActionView::Helpers

  before_validation :construct_action
  validate :check_action_text

  def type_abbr
    'Send message'
  end

  def description
    'Send a message to the subscriber'
  end

  def check_action_text
    if !(as_text=~/^Send message \d+$/)
      errors.add :as_text, "action format is invalid"
    end
  end

  def construct_action
    self.as_text = "Send message #{message_to_send}"
  end

  def execute(opts={})
    if opts[:subscribers].nil? || opts[:subscribers].empty?
      Rails.logger.info "info=no_subscribers_in_action_opts class=send_message_action action_id=#{self.id} message_id=#{opts[:message].try(:[], 'id')}"
      return false
    end
    subscribers = opts[:subscribers]
    message = Message.find_by_id(message_to_send)
    if !message
      Rails.logger.info "info=message_not_found_from_action_opts class=send_message_action action_id=#{self.id} message_id=#{opts[:message].try(:[], 'id')}"
      return false
    end
    MessagingManager.new_instance.broadcast_message(message,subscribers)
    message.perform_post_send_ops(subscribers)
    return true
  rescue => e
    Rails.logger.error "error=raise class=send_message_action action_id=#{self.id} message_id=#{opts[:message].try(:[], 'id')} message='#{e.message}'"
    return false
  end
end
