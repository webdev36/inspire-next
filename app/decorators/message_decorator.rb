class MessageDecorator < Draper::Decorator
  delegate_all




  def title_text
    h.raw("#{message_icon} #{message_display_text}")
  end

  def message_icon
    case type
    when 'ActionMessage'
      "<i class='fa fa-gears' title='MessageID: #{self.id} - Takes action on behalf of a subscriber'></i>"
    when 'TagMessage'
      "<i class='fa fa-tag' title='MessageID: #{self.id} - Sends conditional message depending on tags of subscriber'></i>"
    when 'ResponseMessage'
      "<i class='fa fa-mail-forward' title='MessageID: #{self.id} - Sends message with reminders, and takes action on responses.'></i>"
    when 'PollMessage'
      "<i class='fa fa-list-ul' title='MessageID: #{self.id} - Sends a question with a set of responses. Aggregates answers.'></i>"
    when 'SimpleMessage'
      "<i class='fa fa-envelope' title='MessageID: #{self.id} - Sends a message to a subscriber.'></i>"
    else
      "<i class='fa fa-envelope' title='MessageID: #{self.id} - Sends a message to a subscriber.'></i>"
    end
  end

  def message_display_text
    case type
    when 'ActionMessage'
      action_message_text
    when 'TagMessage'
      tag_message_text
    else
      default_message_text
    end
  end

  def action_message_text
    action.as_text
  end

  def tag_message_text
    mo = self.message_options.sample
    "#{mo.key}: #{mo.value[0..100]} and #{self.message_options.count} other tags"
  end

  def default_message_text
    caption.to_s[0..100]
  end

end
