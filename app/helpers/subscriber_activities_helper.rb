module SubscriberActivitiesHelper
  def sa_title(target,criteria,type,unprocessed)
    content = ''
    case type
    when 'SubscriberResponse'
      content.concat 'Subscriber responses '
    when 'DeliveryNotice'
      content.concat 'Delivery notices '
    else
      content.concat 'Subscriber activities '
    end
    if unprocessed
      content.concat '(unprocessed)'
    end
    case criteria
    when 'Subscriber'
      content.concat " of #{target.name}"
    when 'Channel'
      content.concat " of #{target.name}"
    when 'ChannelGroup'
      content.concat " of #{target.name}"
    when 'Message'
      content.concat " for '#{target.caption[0..30]}'"
    end

    content
  end

  def sa_description(sa)
    content=''
    case sa.type
    when 'DeliveryNotice'
      content.concat "We sent "
      message_brief=''
      if sa.options && sa.options[:reminder_message]==true
        message_brief = "reminder message"
        content.concat message_brief
      elsif sa.options && sa.options[:repeat_reminder_message]==true
        message_brief = "repeat reminder message"
        content.concat message_brief
      elsif sa.message.present? && sa.message.caption.present?
        message_brief = "'#{sa.message.caption[0,30]}'" 
        content.concat link_to(message_brief,channel_message_path(sa.message.channel,sa.message)) 
      end
      content.concat " to "
      content.concat link_to(sa.subscriber.name,subscriber_path(sa.subscriber)) if sa.subscriber.present?
    when 'SubscriberResponse'
      if sa.subscriber
        content.concat link_to(sa.subscriber.name,subscriber_path(sa.subscriber)) if sa.subscriber.present?
      else
        content.concat sa.origin
      end
      content.concat " sent"
      content.concat " '#{sa.caption}'"
    when 'ActionNotice'
      content = sa.caption
    end
    content.html_safe
  end

  def sa_delivery_notice_message_fields(sa)
    content=''
    if sa.options[:reminder_message]
      content.concat "<dt><strong>Type:</strong></dt><dd>Reminder message<dd>"
      if sa.message
        content.concat "<dt><strong>Original Message:</strong></dt><dd>"
        content.concat link_to(print_or_dashes(sa.message.caption[0..80]),
         channel_message_path(sa.message.channel, sa.message))
        content.concat "</dd>"
      end
    elsif sa.options[:repeat_reminder_message]
      content.concat "<dt><strong>Type:</strong></dt><dd>Repeat reminder message<dd>"
      if sa.message
        content.concat "<dt><strong>Original Message:</strong></dt><dd>"
        content.concat link_to(print_or_dashes(sa.message.caption[0..80]),
         channel_message_path(sa.message.channel, sa.message))
        content.concat "</dd>"
      end      
    elsif sa.message
      content.concat "<dt><strong>Message:</strong></dt><dd>"
      content.concat link_to(print_or_dashes(sa.message.caption[0..80]),
       channel_message_path(sa.message.channel, sa.message))
      content.concat "</dd>"
    end
    content.html_safe
  end

 def sa_path(sa)
   case sa.parent_type
   when :message
     {:controller=>'subscriber_activities',:message_id => sa.message.id,:channel_id=>sa.channel.id,:id=>sa.id}
   when :subscriber
     {:controller=>'subscriber_activities',:subscriber_id => sa.subscriber.id,:id=>sa.id}
   when :channel
     {:controller=>'subscriber_activities',:channel_id => sa.channel.id,:id=>sa.id}
   when :channel_group
     {:controller=>'subscriber_activities',:channel_group_id => sa.channel_group.id,:id=>sa.id}
   end
 end 

end