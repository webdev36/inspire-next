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

  def broadcast_message(message,subscribers)

    phone_numbers = subscribers.map(&:phone_number)
    content_url = message.content.exists? ? message.content.url : nil
    from_num=nil

    if message.options && message.options[:tparty_keyword].present?
      from_num = message.options[:tparty_keyword]

    elsif message.channel && message.channel.tparty_keyword.present?
      from_num = message.channel.tparty_keyword
    end

    subscribers.each do |subscriber|
      if message.is_a?(TagMessage)
        if !message.message_text?(subscriber)
          Rails.logger.info "Skipping Subscriber #{subscriber.id} for message #{message.id} due to no matching key."
          next
        end
      end

      title_text = get_final_message_title(message,subscriber)
      message_text = get_final_message_content(message,subscriber)

      if send_message(subscriber.phone_number,title_text,message_text,
          content_url,from_num)

        if message.primary?
          dn = DeliveryNotice.create(message:message,title:title_text,caption:message_text,subscriber:subscriber,options:message.options)
        else
          dn = DeliveryNotice.create(message:Message.find(message.options[:message_id]),subscriber:subscriber,
            options:message.options)
        end
        Rails.logger.info("DeliveryNotice:#{dn.nil? ? 'nil' : dn.id} for Message:#{message.id} Subscriber:#{subscriber.id}")
      else
        Rails.logger.error("Broadcast message #{message.caption} failed")
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
