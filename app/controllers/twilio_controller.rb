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
        Rails.logger.error "action=create_subscriber_response error=body_blank from=twilio_controller status=error body='#{params['Body']}' from='#{params['From']}' to='#{params['To']}'"
        return false
      end
      if params["From"].blank?
        Rails.logger.error "action=create_subscriber_response error=from_blank from=twilio_controller status=error body='#{params['Body']}' from='#{params['From']}' to='#{params['To']}'"
        return false
      end
      sr = SubscriberResponse.create(caption: params["Body"].downcase,
           origin: Subscriber.format_phone_number(params["From"]),
           tparty_identifier: Subscriber.format_phone_number(params["To"]))
      sr.try_processing
      Rails.logger.info "action=create_subscriber_response from=twilio_controller status=ok body='#{params['Body']}' from='#{params['From']}' to='#{params['To']}'"
      true
    rescue => e
      Rails.logger.error "action=create_subscriber_response from=twilio_controller status=error error_message='#{e.message}' body='#{params['Body']}' from='#{params['From']}' to='#{params['To']}'"
      false
    end

end
