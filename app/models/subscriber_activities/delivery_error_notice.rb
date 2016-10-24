class DeliveryErrorNotice < SubscriberActivity
  attr_accessible :subscriber, :message, :channel, :channel_group

  after_initialize do |dn|
    if dn.new_record?
      begin
        dn.processed = true
      rescue ActiveModel::MissingAttributeError
      end
    end
  end

  def self.of_primary_messages
    includes(:message).where("messages.primary=true").references(:messages)
  end

  def self.of_primary_messages_that_require_response
    includes(:message).where("messages.primary=true AND messages.requires_response=true").references(:messages)
  end

end
