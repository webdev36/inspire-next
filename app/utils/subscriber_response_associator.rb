class SubscriberResponseAssociator
  attr_reader :subscriber_response

  def initialize(subscriber_response)
    @subscriber_response = subscriber_response
  end

  def run
    recommendation
  end

  def recommendation
    recommendation = nil
    if has_expected_responses?
      recommendation = most_recent_matching_message_response
    end
    if recommendation.nil? && has_response_expecting_delivery_notices?
      recommendation = first_response_expecting_dn
    end
    if recommendation.nil?
      recommendation = first_delivery_notice
    end
    recommendation
  end

  def caption
    subscriber_response.caption
  end

  # sr.content_text =~ /#{ra.response_text}/im
  def most_recent_matching_message_response
    message_id = nil
    expected_responses_map.keys.each do |key|
      if !(caption !~ /#{key}/im) # if the caption contains the string
        message_id = expected_responses_map[key].try(:first)
        Rails.logger.info "class=subscriber_response_associator info=matched_subscriber_response caption='#{caption}' key='#{key}' message_id=#{message_id} subscriber_response_id=#{subscriber_response.id}"
        break
      end
    end
    msg = Message.find(message_id) if message_id
    if msg
      { message_id: msg.id, channel_id: msg.channel_id }
    end
  end

  def has_expected_responses?
    expected_responses_map.keys.length > 0
  end

  def has_response_expecting_delivery_notices?
    response_expecting_delivery_notices.length > 0
  end

  def first_response_expecting_dn
    resp = nil
    dn = response_expecting_delivery_notices&.first
    resp = { message_id: dn.message_id, channel_id: dn.channel_id } if dn
    resp
  end

  def first_delivery_notice
    resp = nil
    dn = delivery_notices&.first
    resp = { message_id: dn.message_id, channel_id: dn.channel_id } if dn
    resp
  end

  def subscriber
    @subscriber ||= subscriber_response.subscriber
  end

  def delivery_notices
    @delivery_notices ||= subscriber.delivery_notices
                                    .where(created_at: 23.hours.ago..Time.now)
                                    .where(channel_id: potential_channel_ids)
                                    .order(created_at: :desc)
                                    .includes(:message)
  end

  def potential_channel_ids
    @potential_channel_ids ||= begin
      pcids = []
      Channel.by_tparty_keyword(subscriber_response.tparty_identifier).pluck(:id).each { |id| pcids << id }
      ChannelGroup.where(:tparty_keyword => subscriber_response.tparty_identifier)
                  .includes(:channels).pluck('channels.id').each { |id| pcids << id }
      pcids.uniq
    end
  end

  def expected_responses_map
    @expected_responses_map ||= begin
      erm = {}
      response_expecting_delivery_notices.each do |dn|
        dn.message.response_actions.each do |ra|
          erm[ra.response_text] = [] if erm[ra.response_text].blank?
          erm[ra.response_text] << dn.message.id
        end
      end
      erm
    end
  end

  def response_expecting_delivery_notices
    delivery_notices_by_types(['ResponseMessage', 'PollMessage'])
  end

  def response_message_delivery_notices
    delivery_notices_by_types('ResponseMessage')
  end

  def delivery_notices_by_types(types)
    delivery_notices.select { |dn| Array(types).include?(dn.message.type) }
  end
end

