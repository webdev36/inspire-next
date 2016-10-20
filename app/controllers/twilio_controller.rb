class TwilioController < ApplicationController
  def callback
    Rails.logger.info "Twilio_Callback: #{params}"
    if !handle_request(params)
      Rails.logger.error "Twilio controller could not handle: #{params}"
      render :text=>"Wrong request", :status => 500
    else
      render :text=>'OK', :status =>200
    end
  end

  private

  def handle_request(params)
    if params["Body"].blank?
      return false
    end
    if params["From"].blank?
      return false
    end
    sr = SubscriberResponse.create(caption:params["Body"].downcase,
         origin:Subscriber.format_phone_number(params["From"]),
         tparty_identifier:Subscriber.format_phone_number(params["To"]))
    sr.try_processing
    true
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    false
  end

end
