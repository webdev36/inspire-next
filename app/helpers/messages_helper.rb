module MessagesHelper
  def message_types
    (Message.subclasses.map(&:to_s)).map(&:to_sym)
  end

  def user_message_types
    arr=[]
    ::Message.child_classes.each do |klass|
      if klass.user_accessible_message_type?
        arr << klass.to_s.to_sym
      end
    end
    if arr.blank?
      arr = MESSAGE_TYPES
    end
    arr
  end

  def base_message_length(message)
    bml = ENV['TPARTY_SUFFIX_LENGTH'].to_i
    bml += message.channel.suffix.length if message.channel && message.channel.suffix
    bml
  end

  def total_message_length(message)
    tml = base_message_length(message)
    tml += message.caption.length if message.caption
    tml
  end

  def convert_to_message_link(text)
    if text.include?("Send message")
      message_id = text.split(' ').last
      message = Message.find(message_id)
    end
    if message
      link_to(text, channel_message_path(message.channel.id, message.id))
    else
      text
    end
  end

end
