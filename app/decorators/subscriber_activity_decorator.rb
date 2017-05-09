class SubscriberActivityDecorator < Draper::Decorator
  delegate_all

  def subscriber_name
    self.subscriber&.name || subscriber&.phone_number
  end

  def subscriber_phone_number
    self.subscriber&.phone_number
  end

  def icon
    case type
    when 'DeliveryNotice'
      h.raw "<i class='fa fa-envelope fa-2x color-info' title='A message was delivered to a subscriber'></i>"
    when 'DeliveryErrorNotice'
      h.raw "<i class='fa fa-exclamation fa-2x color-danger' title='There was an error delivering a message to a subscriber.'></i>"
    when 'SubscriberResponse'
      h.raw "<i class='fa fa-reply fa-2x color-success' title='A subscriber responded.'></i>"
    when 'ActionNotice'
      h.raw "<i class='fa fa-bolt fa-2x color-info' title='An action was taken on behalf of the subscriber.'></i>"
    else
      h.raw "<i class='fa fa-square fa-2x color-warning' title='This is an unknown reponse type.'></i>"
    end
  end

  def display_text
    case type
    when 'DeliveryNotice'
      delivery_notice_text
    when 'DeliveryErrorNotice'
      delivery_error_notice_text
    when 'ActionNotice'
      action_notice_text
    when 'SubscriberResponse'
      subscriber_response_text
    else
      "Please contact support for more information."
    end
  end

  def action_notice_text
    "#{caption}"
  end

  def delivery_error_notice_text
    "Error sending message: '#{options['error'].try(:titleize)}'"
  end

  def subscriber_response_text
    "The subscriber replied: '#{caption}'"
  end

  def delivery_notice_text
    if options[:message_id] && options[:repeat_reminder_message]
      "Sent <a href='/channels/#{original_message.channel_id}/messages/#{original_message.id}'>repeat reminder message</a>: '#{message.original_message&.repeat_reminder_message_text}'"
    elsif options[:message_id] && options[:reminder_message]
      "Sent <a href='/channels/#{original_message.channel_id}/messages/#{original_message.id}'>reminder message</a>: '#{original_message&.reminder_message_text}'"
    else
      "Sent <a href='/channels/#{original_message.channel_id}/messages/#{original_message.id}'>original message</a>: '#{caption}'"
    end
  end
end
