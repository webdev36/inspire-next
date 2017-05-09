require 'chronic'

# building out over time, try to follow how Salesforce does it
 # https://help.salesforce.com/articleView?id=customize_functions.htm&type=0
module Mixins
  module RuleDSL
    extend ActiveSupport::Concern

    def date_is_today?(supplied_date)
      errors_are_false do
        ensure_date(supplied_date).today?
      end
    end

    def date_is_tomorrow?(supplied_date)
      errors_are_false do
        ensure_date(supplied_date).to_date == Date.tomorrow
      end
    end

    def date_is_yesterday?(supplied_date)
      errors_are_false do
        ensure_date(supplied_date).to_date == Date.yesterday
      end
    end

    # could also handle other cases where the date supplied might not parse well
    def ensure_date(supplied_date)
      sd = Chronic.parse(supplied_date) if supplied_date.is_a? String
      sd
    end

    # date is x days away walys rounds up
    def date_is_x_days_away?(supplied_date, days_away)
      errors_are_false do
        seconds_delta = ensure_date(supplied_date) - Time.now
        days_delta = (seconds_delta / 86400.0).ceil
        days_away == days_delta
      end
    end
    alias_method :date_is_X_days_away?, :date_is_x_days_away?

    def subscriber_is_in_channel?(subscribed_ids, channel_id)
      errors_are_false do
        subscribed_ids.map(&:to_i).include?(channel_id.to_i)
      end
    end

    def subscriber_is_not_in_channel?(subscribed_ids, channel_id)
      errors_are_false do
        !subscribed_ids.map(&:to_i).include?(channel_id.to_i)
      end
    end

    private

    def errors_are_false
      yield
    rescue => e
      puts "ERROR: #{e.message}"
      false
    end
  end
end
