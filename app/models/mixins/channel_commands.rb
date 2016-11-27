module Mixins
  module ChannelCommands
    extend ActiveSupport::Concern

    class_methods do
      def identify_command(message_text)
        return :custom if message_text.blank?
        tokens = message_text.split
        if tokens.length == 1
          case tokens[0]
          when /start/i
            return :start
          when /stop/i
            return :stop
          when /subscriptions/i
            return :subscriptions
          else
            return :custom
          end
        elsif tokens.length > 1
          case tokens[0]
          when /set/i
            return :set
          when /get/i
            return :get
          else
            return :custom
          end
        end
      end
    end

    def send_tracked_message_to_subscriber(subscriber, message_text, tparty_identifier)
      if MessagingManager.new_instance.send_message(subscriber.phone_number, '', message_text, nil, tparty_identifier )
        dn = DeliveryNotice.create(message: nil, title: nil,
                                   caption: message_text, subscriber: subscriber,
                                   options: {} )
        true
      else
        false
      end
    end

    def handle_subscriber_response_error(subscriber_response, error_type, action)
      StatsD.increment("#{self.class.name.downcase}.#{self.id}.subscriber_response.#{subscriber_response.id}.#{error_type.underscore}")
      Rails.logger.error "error=#{error_type.downcase.gsub(' ', '_')} message='Subscriber phone #{error_type}' subscriber_response_id=#{subscriber_response.id} #{self.class.name.downcase}_id=#{self.id}"
      subscriber_response.update_processing_log("Received #{action} command, but #{error_type}")
    end

    def handle_subscriber_response_success(subscriber_response, info_type, action)
      StatsD.increment("#{self.class.name.downcase}.#{self.id}.subscriber_response.#{subscriber_response.id}.#{info_type.underscore}")
      Rails.logger.info "info=#{info_type.underscore} subscriber_response_id=#{subscriber_response.id} #{self.class.name.downcase}_id=#{self.id}"
      subscriber_response.update_processing_log("#{action.titleize} command: #{info_type}")
    end

    def identify_command(message_text)
      self.class.identify_command(message_text)
    end

    def process_subscriber_response(subscriber_response)
      command = identify_command(subscriber_response.content_text)
      case command
      when :start
        process_start_command(subscriber_response)
      when :stop
        process_stop_command(subscriber_response)
      when :subscriptions
        process_subscriptions_command(subscriber_response)
      when :set
        process_set_command(subscriber_response)
      when :get
        process_get_command(subscriber_response)
      when :custom
        process_custom_command(subscriber_response)
      else
        handle_subscriber_response_error(subscriber_response, 'command not identitied', 'command_switch')
        false
      end
    end

    def process_subscriptions_command(subscriber_response)
      subscriber = find_subscriber_for_subscriber_response(subscriber_response)
      if subscriber
        subscriber_subscription_message = ['You have the following subscriptions:\n']
        subscriber.subscriptions.each do |subscription|
          if subscription.channel.keyword.blank?
            subscriber_subscription_message << "#{subscription.channel.name} - no keyword for this channel."
          else
            subscriber_subscription_message << "#{subscription.channel.name} - #{subscription.channel.keyword}"
          end
        end
        subscriber_subscription_message << "You nave no subscriptions." if subscriber.subscriptions.length == 0
        message_to_send = subscriber_subscription_message.join("\n")
        resp = send_tracked_message_to_subscriber(subscriber, message_to_send, subscriber_response.tparty_identifier)
        if resp
          handle_subscriber_response_success(subscriber_response, 'subscriptions command requested', 'subscription')
        else
          handle_subscriber_response_error(subscriber_response, 'unable to send subscriptions', 'subscription')
        end
      end
      true
    end

    def process_set_command(subscriber_response)
      subscriber = find_subscriber_for_subscriber_response(subscriber_response)
      if subscriber
        tokens = subscriber_response.content_text.split(' ', 2)
        key, value = tokens[1].to_s.split("=", 2)
        subscriber.update_custom_attribute(key, value)
        message_to_send = "We've updated your #{key} to #{value}."
        resp = send_tracked_message_to_subscriber(subscriber, message_to_send, subscriber_response.tparty_identifier)
        if resp
          handle_subscriber_response_success(subscriber_response, "set command: #{key} = #{value}", 'set')
        else
          handle_subscriber_response_error(subscriber_response, "set command: #{key} = #{value}", 'set')
        end
      end
      true
    end

    def process_get_command(subscriber_response)
      subscriber = find_subscriber_for_subscriber_response(subscriber_response)
      if subscriber
        tokens = subscriber_response.content_text.split(' ', 2)
        key = tokens[1].to_s.strip.downcase
        value = subscriber.custom_attributes.try(:[], key)
        if value
          message_to_send = "Your #{key} is #{value}."
        else
          message_to_send = "You do not have a #{key} value saved."
        end
        resp = send_tracked_message_to_subscriber(subscriber, message_to_send, subscriber_response.tparty_identifier)
        if resp
          handle_subscriber_response_success(subscriber_response, "get command: #{key}", 'get')
        else
          handle_subscriber_response_error(subscriber_response, "get command: #{key}", 'get')
        end
      end
      true
    end

    def find_subscriber_for_subscriber_response(subscriber_response)
      subscriber = false
      phone_number = subscriber_response.origin
      if !phone_number || phone_number.blank?
        handle_subscriber_response_error(subscriber_response, 'no phone number supplied', 'subscription')
        return false
      end
      subscriber = user.subscribers.find_by_phone_number(phone_number)
      if !subscriber
        handle_subscriber_response_error(subscriber_response, 'subscriber not found', 'subscription')
        return false
      end
      subscriber
    end

  end
end
