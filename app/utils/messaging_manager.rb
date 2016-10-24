class MessagingManager

  def self.new_instance
    mmclass.new
  end

  def self.mmclass
    return case ENV['TPARTY_MESSAGING_SYSTEM']
    when 'Twilio'
      TwilioMessagingManager
    else
      TwilioMessagingManager
    end
  end

  def broadcast_message(message, subscribers)

    phone_numbers = subscribers.map(&:phone_number)
    content_url = message.content.exists? ? message.content.url : nil
    from_num = nil

    if message.options && message.options[:tparty_keyword].present?
      from_num = message.options[:tparty_keyword]

    elsif message.channel && message.channel.tparty_keyword.present?
      from_num = message.channel.tparty_keyword
    end

    subscribers.each do |subscriber|
      if message.is_a?(TagMessage)
        if !message.message_text?(subscriber)
          Rails.logger.info "action=send_message status=error error=no_matching_tag_key action=send_message subscriber_id=#{subscriber.id} message_id=#{message.id} method=broadcast_message"
          next
        end
      end

      title_text =   get_final_message_title(message,subscriber)
      message_text = get_final_message_content(message,subscriber)

      if DeliveryNotice.where(:subscriber_id => subscriber.id).recently_sent.count > 4
        StatsD.increment("subscriber.#{subscriber.id}.skip_flood_protection")
        Rails.logger.error "action=send_message status=error error=too_many_recently_sent_messages subscriber_id=#{subscriber.id} message_id=#{message.id} caption='#{message.caption}'"
        DeliveryErrorNotice.create(message: message, title: title_text, caption: message_text,
                                   subscriber: subscriber, options: message.options.merge('error' => 'Has been sent too many messages recently. Rate limiting.'))
        next
       end
      if send_message(subscriber.phone_number, title_text, message_text, content_url, from_num)
        if message.primary?
          StatsD.increment("subscriber.#{subscriber.id}.message.#{message.id}.sent_primary")
          dn = DeliveryNotice.create(message: message,      title: title_text,
                                     caption: message_text, subscriber: subscriber,
                                     options: message.options )
        else
          StatsD.increment("subscriber.#{subscriber.id}.message.#{message.options[:message_id]}.sent_reminder")
          dn = DeliveryNotice.create(message: Message.find(message.options[:message_id]),
                                     title: title_text,     caption: message_text,
                                     subscriber:subscriber, options: message.options)
        end
        Rails.logger.info "action=send_message status=ok delivery_notice_id=#{dn.nil? ? 'nil' : dn.id} message_id=#{message.options[:message_id] ? message.options[:message_id] : message.id} primary_message=#{message.primary?} subscriber_id=#{subscriber.id} method=broadcast_message caption='#{message_text}' reminder_message=#{message.options[:reminder_message] ? 'y' : 'n'} repeat_reminder_message=#{message.options[:repeat_reminder_message] ? 'y' : 'n'}"
      else
        StatsD.increment("subscriber.#{subscriber.id}.message.#{message.id}.send_message_error")
        Rails.logger.error "action=send_message status=error subscriber_id=#{subscriber.id} message_id=#{message.id} caption='#{message.caption}'"
      end
    end
  end

  def get_final_message_content(message,subscriber)
    if message.is_a?(TagMessage)
      message_text = message.caption_for(subscriber)
    else
      message_text = message.caption
    end
    message_text += " #{message.channel.suffix}" if message.channel && message.channel.suffix.present?
    message_text
  end

  def get_final_message_title(message,subscriber)
    message.title
  end

  #Override methods

  def send_message(phone_number,title,message_text,content_url,from_num)
  end

  def validate_tparty_keyword(value)
  end

  def add_keyword(keyword)
  end

  def remove_keyword(keyword)
  end

  # Whether the external service uses message itself to differentiate target of MO messages
  def keyword_based_service?
  end


private

  def self.substitute_placeholders(content,placeholders)
    attr_value_pairs={}
    if placeholders
      placeholders.split(";").each do |str|
        if (md = str.match(/(.+)=(.+)/))
          attr_value_pairs[md[1].upcase]=md[2]
        end
      end
    end
    attr_value_pairs.each do |attr,value|
      content.gsub!(/\%\%#{attr}\%\%/i,value)
    end
    content.gsub!(/\%\%.+\%\%/,"")
    content
  end

end
