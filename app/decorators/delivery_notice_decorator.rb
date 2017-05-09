class DeliveryNoticeDecorator < Draper::Decorator
  decorates DeliveryNotice
  delegate_all

  def sent_message
    if options[:message_id]
      if options[:reminder_message]
        original_message.reminder_message
      elsif options[:repeat_reminder_message]
        original_message.repeat_reminder_message
      else
        original_message.caption
      end
    else
      caption
    end
  end

  def original_mesasge_id
    original_message.id
  end

  def original_channel_id
    original_message.channel.id
  end

  def original_message
    @original_message ||= begin
      if options[:message_id]
        Message.where(:id => options[:message_id]).try(:first)
      else
        self
      end
    end
  end

end
