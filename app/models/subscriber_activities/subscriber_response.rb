# == Schema Information
#
# Table name: subscriber_activities
#
#  id               :integer          not null, primary key
#  subscriber_id    :integer
#  channel_id       :integer
#  message_id       :integer
#  type             :string(255)
#  origin           :string(255)
#  title            :text
#  caption          :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  channel_group_id :integer
#  processed        :boolean
#  deleted_at       :datetime
#

class SubscriberResponse < SubscriberActivity
  after_create :assign_channel_and_subscriber, :send_stats_d_update
  before_validation :case_convert_message

  def self.parse_message(pmessage_text,tparty_identifier=nil)
    response = nil
    #Hack. For twilio, the tparty identifier is not part of message. Just add it, so existing parsing algo works.
    message_text = tparty_identifier.present? ? "#{tparty_identifier} #{pmessage_text}" : pmessage_text
    if message_text.blank?
      return [nil,nil,nil,'']
    end
    message = message_text.split
    case
    when message.length == 1
      if ChannelGroup.by_tparty_keyword(message[0]).count == 1
        response = [ChannelGroup.by_tparty_keyword(message[0]).first, message[0],nil,'']
      elsif Channel.by_tparty_keyword(message[0]).count == 1
        response = [Channel.by_tparty_keyword(message[0]).first, message[0],nil,'']
      else
        response = [nil,nil,nil,message[0]]
      end
    when message.length >= 2
      if ChannelGroup.by_tparty_keyword(message[0]).by_keyword(message[1]).count == 1
        target = ChannelGroup.by_tparty_keyword(message[0]).by_keyword(message[1]).first
        tkw = message.shift
        kw = message.shift
        mes = message.join(' ')
        response = [target,tkw,kw,mes]
      elsif Channel.by_tparty_keyword(message[0]).by_keyword(message[1]).count == 1
        target = Channel.by_tparty_keyword(message[0]).by_keyword(message[1]).first
        tkw = message.shift
        kw = message.shift
        mes = message.join(' ')
        response = [target,tkw,kw,mes]
      elsif  ChannelGroup.by_tparty_keyword(message[0]).count == 1
        target = ChannelGroup.by_tparty_keyword(message[0]).first
        tkw = message.shift
        kw = nil
        mes = message.join(' ')
        response = [target,tkw,kw,mes]
      elsif Channel.by_tparty_keyword(message[0]).count == 1
        target = Channel.by_tparty_keyword(message[0]).first
        tkw = message.shift
        kw = nil
        mes = message.join(' ')
        response = [target,tkw,kw,mes]
      else
        response = [nil,nil,nil,message.join(' ')]
      end
    end
    response
  end

  # this is where the logic for matching up to a channel and a subscriber are
  def assign_channel_and_subscriber
    target_channel, t_tparty_keyword, t_keyword, t_message = SubscriberResponse.parse_message(caption,tparty_identifier)
    if target_channel
      target_channel.subscriber_responses << self
      if target_channel.user
        registered_subscribers = target_channel.user.subscribers
        if registered_subscribers
          t_subs = registered_subscribers.find_by_phone_number(origin)
          t_subs.subscriber_responses << self if t_subs
        end
      end
    end
  end

  def target
    if channel_group
      return channel_group
    elsif channel
      return channel
    end
  end

  def tparty_keyword
    t_target,t_tparty_keyword,t_keyword,t_message = SubscriberResponse.parse_message(caption,tparty_identifier)
    t_tparty_keyword
  end

  def keyword
    t_target,t_tparty_keyword,t_keyword,t_message = SubscriberResponse.parse_message(caption,tparty_identifier)
    t_keyword
  end

  def content_text
    t_target,t_tparty_keyword,t_keyword,t_message = SubscriberResponse.parse_message(caption,tparty_identifier)
    t_message
  end

  def process
    assign_channel_and_subscriber rescue false
    try_processing
  end

  def caption_first_word
    self.caption&.to_s&.downcase&.split&.first
  end

  def try_processing
    if target && target.process_subscriber_response(self)
      self.processed = true
      save
      return true
    else
      return false
    end
  rescue => e
    StatsD.increment("subscriber_response.#{self.id}.subscriber_response_raise")
    Rails.logger.error("error=raise_try_processing message='#{e.message}' class=subscriber_response")
    return false
  end

  def send_stats_d_update
    StatsD.increment("subscriber.#{subscriber_id}.subscriber_response")
  end

  private

  def case_convert_message
    self.caption = caption.downcase if caption
    self.title = title.downcase if title
  end

end
