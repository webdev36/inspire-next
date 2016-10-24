module SubscriberMessageSent

  def self.has_already_been_sent_message?(subscriber_id, message_id)
    self.delivery_notice_for_message?(subscriber_id, message_id) || self.delivery_error_notice_for_message?(subscriber_id, message_id)
  end

  def self.delivery_notice_for_message?(subscriber_id, message_id)
    DeliveryNotice.of_primary_messages.where(message_id:message_id, subscriber_id:subscriber_id).exists?
  end

  def self.delivery_error_notice_for_message?(subscriber_id, message_id)
    DeliveryErrorNotice.of_primary_messages.where(message_id:message_id, subscriber_id:subscriber_id).exists?
  end

end
