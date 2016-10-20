class TwilioMessagingManager < MessagingManager
  attr_accessor :twrapper
  
  def initialize(pwrapper=nil)
    @twrapper = pwrapper || TwilioWrapper.new
  end  

  def send_message(phone_number,title,message_text,content_url,from_num)
    if from_num.nil?
      Rails.logger.error "TwillioNumber is not configured. Broadcast_message failed"
      return false
    end
    return twrapper.send_message(phone_number,title,message_text,content_url,from_num)
  end


  def validate_tparty_keyword(value)
    nil
  end  


  def add_keyword(keyword)
    true
  end

  def remove_keyword(keyword)
    true
  end

  def self.keyword_based_service?
    false
  end


end