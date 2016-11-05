# this module gives us a global ability to control the twilio wrapper
# dynamically, setting and unsetting varialbes using the commmand line

module Liveinspired

  def self.turn_off_message_sending!
    ENV['DO_NOT_SEND'] = 'true'
    redis_do_not_send = true
    TwilioWrapper.mock_calls = true
  end

  def self.turn_on_message_sending!
    ENV['DO_NOT_SEND'] = nil
    redis_do_not_send = false
    TwilioWrapper.mock_calls = false
  end

  def self.ok_to_send
    do_not_send == false
  end

  def self.do_not_send
    [true, 'true'].include?(redis_do_not_send) || [true, 'true'].include?(ENV['DO_NOT_SEND']) || !Rails.env.production?
  end

  def self.redis_do_not_send=(val)
    REDIS.set('inspire.do_not_send', val)
  end

  def self.redis_do_not_send
    REDIS.get('inspire.do_not_send')
  end
end

puts "Twilio API is set to Liveinspired.do_not_send=#{Liveinspired.do_not_send}"
