class ResponseActionDecorator < Draper::Decorator
  delegate_all

  def channel_name
    "#{message.channel.name}"
  end

  def type
    action.type
  end

  def message
    @message ||= Message.find(message_id)
  end

  def channel
    @channel ||= Channel.find(message.channel_id)
  end

  def message_summary
    "#{message.id} - #{message.caption.slice(0,20)}"
  end

  def message_link
    reply = nil
    if type == 'SendMessageAction'
      reply = h.link_to "Send message to #{message.id}", "/channels/#{channel.id}/messages/#{message.id}"
    elsif type == 'SwitchChannelAction'
      if switch_channel_as_text_channel_id
        reply = h.link_to "Switch to channel #{switch_channel_as_text_channel_id}", "/channels/#{switch_channel_as_text_channel_id}"
      end
    end
    reply
  end

  def as_text
    action.as_text
  end

  def switch_channel_as_text_channel_id
    @switch_channel_as_text_channel_id ||= as_text.to_s.scan(/\ASwitch channel to (\d+)\z/).try(:flatten).try(:first)
  end

end
