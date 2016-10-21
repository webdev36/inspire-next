module ChannelsHelper

  def channel_types
    (Channel.subclasses.map(&:to_s)).map(&:to_sym)
  end

  def user_channel_types
    Channel.subclasses.select { |c| !c.system_channel? }.map { |c| c.to_s.to_sym }
  end

  def channel_schedulable?(channel_type)
    case channel_type
    when "AnnouncementsChannel","OnDemandMessagesChannel",
      "IndividuallyScheduledMessagesChannel"
      return false
    when "OrderedMessagesChannel","RandomMessagesChannel",
      "ScheduledMessagesChannel"
      return true
    end
    return false
  end

  def message_subtext(channel,message,index)
    if channel.individual_messages_have_schedule?
      if channel.relative_schedule?
        content_tag(:div,message.schedule,class:'small').html_safe
      else
        content_tag(:div,message.next_send_time.strftime("%c"),class:'small').html_safe if message.next_send_time
      end
    elsif channel.sequenced? && channel.has_schedule?
      schedule = channel.converted_schedule
      if schedule
        content_tag(:div,schedule.next_occurrences(index+1)[index].strftime("%c"),class:'small').html_safe
      end
    end
  end

end
