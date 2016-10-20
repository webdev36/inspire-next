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
    return false if opts[:subscribers].nil? || opts[:subscribers].empty?
    subscribers = opts[:subscribers]
    message = Message.find_by_id(message_to_send)
    return false if !message
    MessagingManager.new_instance.broadcast_message(message,subscribers)
    message.perform_post_send_ops(subscribers)
    return true
  rescue
    return false
  end
end
