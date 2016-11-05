require 'twilio-ruby'

class TwilioWrapper
  attr_accessor :client

  @@mock_calls = true
  @@mock_calls = true if Rails.env == "test"

  def initialize(pclient=nil)
    @client = pclient || Twilio::REST::Client.new(sid, auth)
    if Rails.env.production?
      @mock = false
    elsif @@mock_calls
      @mock = true
    else
      @mock = false
    end
    # no matter what, if there is a "DO_NOT_SEND" that is true, then do not
    # send messages
    if ENV['DO_NOT_SEND']
      @mock = true
    end
  end

  def redis_do_not_send?
    [true, 'true'].include?(redis_do_not_send)
  end

  def redis_do_not_send
    REDIS.get('inspire.do_not_send')
  end

  def allowed_to_send?
    !ENV['DO_NOT_SEND'] && mock != true && !redis_do_not_send?
  end

  def sid
    ENV['TWILIO_SID']
  end

  def auth
    ENV['TWILIO_AUTH_TOKEN']
  end

  def send_message(phone_number,title,caption,content_url,from_num)
    if allowed_to_send?
      Rails.logger.info "action=send_message from=twiliow_wrapper status=ok phone_number='#{phone_number}' title='#{title}' caption='#{caption}' content_url='#{content_url}' from_num='#{from_num}'"
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
    else
      Rails.logger.info "action=send_blocked_message from=twiliow_wrapper status=ok phone_number='#{phone_number}' title='#{title}' caption='#{caption}' content_url='#{content_url}' from_num='#{from_num}'"
      log "SENDBLOCKED: send_message(#{phone_number},#{title},#{caption},#{content_url},#{from_num})"
      return true
    end
  end

  def self.mock_calls=(bmock)
    @@mock_calls = bmock
  end

  def mock
    @mock
  end

  private

  def positive?(response,method_name)
    if response && response.code.to_i == 1
      Rails.logger.info "action=twilio_response_check status=ok from=twilio_wrapper method_name='#{method_name}' response='#{response}'"
      true
    else
      Rails.logger.error "action=twilio_response_check status=error from=twilio_wrapper method_name='#{method_name}' response='#{response}'"
      nil
    end
  end

  def log(message)
    File.open(Rails.root.join("/tmp/tparty_server_log_#{Rails.env.to_s}.tsv"),"a") do |f|
      tstr = Time.now.strftime("%c")
      f.puts "#{tstr}\t#{message}"
    end
  end

end
