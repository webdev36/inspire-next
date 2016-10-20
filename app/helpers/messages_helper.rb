module MessagesHelper
  def message_types
    (Message.descendants.map(&:to_s)).map(&:to_sym)
  end

  def user_message_types
    arr=[]
    ::Message.descendants.each do |klass|
      if klass.user_accessible_message_type?
        arr << klass.to_s.to_sym
      end
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

end
