class MessagingManagerWorker
  include Sidekiq::Worker

  def perform(action,opts={})
    case action
    when 'add_keyword'
      self.class.add_keyword(opts['keyword'])
    when 'remove_keyword'
      self.class.remove_keyword(opts['keyword'])
    when 'broadcast_message'
      self.class.broadcast_message(opts['message_id'])
    end
  end

  def self.add_keyword(keyword)
    MessagingManager.new_instance.add_keyword(keyword)
  end

  def self.remove_keyword(keyword)
    MessagingManager.new_instance.remove_keyword(keyword)
  end

  def self.broadcast_message(message_id)
    message = Message.find_by_id(message_id)
    return if !message
    channel = message.channel
    return if !channel
    subscribers = channel.subscribers
    return if subscribers.empty?
    MessagingManager.new_instance.broadcast_message(message,subscribers)
    message.perform_post_send_ops(subscribers)
  end
end