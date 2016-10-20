require 'twilio-ruby'
class TwilioWrapper
  attr_accessor :client
  # reset to true if you are testing
  @@mock_calls = true
  @@mock_calls = true if Rails.env == "test"
  def initialize(pclient=nil)
    @client = pclient || Twilio::REST::Client.new(ENV['TWILIO_SID'],
      ENV['TWILIO_AUTH_TOKEN'])
    if Rails.env.production?
      @mock = false
    elsif @@mock_calls
      @mock = true
    else
      @mock = false
    end
  end

  def send_message(phone_number,title,caption,content_url,from_num)
    if mock
      log "TWILIOMOCK send_message(#{phone_number},#{title},#{caption},#{content_url},#{from_num})"
      return true
    end
    Rails.logger.info "Called:TwilioWrapper#send_message(#{phone_number},#{title},#{caption},#{content_url},#{from_num})"
    h = {from:from_num, body:caption}
    h[:media_url] = content_url if content_url.present?
    h[:to]=phone_number
    begin
      @client.account.messages.create(h)
    rescue => e
      Rails.logger.error e.message
      return false
    end
    return true
  end


  def self.mock_calls=(bmock)
    @@mock_calls = bmock
  end

  def mock
    @mock
  end
  private

  def positive?(response,method_name)
    Rails.logger.info "Twilio Response:#{method_name} #{response}"
    return true if response && response.code.to_i == 1
    Rails.logger.error "TwilioWrapper##{method_name} #{response}"
    nil
  end

  def log(message)
    File.open(Rails.root.join("tparty_server_log_#{Rails.env.to_s}.tsv"),"a") do |f|
      tstr = Time.now.strftime("%c")
      f.puts "#{tstr}\t#{message}"
    end
  end

end
