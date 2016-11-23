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

  scope :unhandled,     -> { where(subscriber_id: nil) }
  scope :last_24_hours, -> { where(created_at: 1.day.ago..Time.now) }
  scope :processed,     -> { where(processed: true) }
  scope :unprocessed,   -> { where(processed: false) }


  def self.parse_message(pmessage_text, tparty_identifier = nil)
    response = nil
    message_text = tparty_identifier.present? ? "#{tparty_identifier} #{pmessage_text}" : pmessage_text
    if message_text.blank?
      Rails.logger.error "class=subscriber_response_class method=parse_message error=unable_to_parse_message message='#{pmessage_text}'"
      response = [nil,nil,nil,'']
    else
      message = message_text.to_s.downcase.split
      case
      when message.length == 1
        response = handle_1_part_message(message)
      when message.length >= 2
        response =handle_multi_part_message(message)
      end
    end
    response
  end

  def self.potential_matching_keywords(tpartykey)
    pmk = Channel.by_tparty_keyword(tpartykey).map{ |x| x.keyword }.delete_if {|x| x.blank? }
    ChannelGroup.by_tparty_keyword(tpartykey).each do |group|
      pmk << group.keyword
    end.delete_if {|x| x.blank? }
    pmk.delete_if {|x| x.blank? }.uniq
  end

  # the only way this can be triggered, would be that the tparrty_keyword is
  # the only thing send, and there is no other message. VERY rare case.
  def self.handle_1_part_message(message)
    response = nil
    if ChannelGroup.by_tparty_keyword(message[0]).count == 1
      response = [ChannelGroup.by_tparty_keyword(message[0]).first, message[0], nil, '']
    elsif Channel.by_tparty_keyword(message[0]).count == 1
      response = [Channel.by_tparty_keyword(message[0]).first, message[0], nil, '']
    else
      response = [nil,nil,nil,message[0]]
    end
    response
  end

  # in all cases, mesasge[0] is the tparty_keyword that is used to find the
  # identifier
  def self.handle_multi_part_message(message)
    response = nil
    channel_keyword, revised_message = channel_keyword_match(message)
    if channel_keyword
      response = find_matching_channel_group_by_tparty_and_keyword(channel_keyword, revised_message)
      response = find_matching_channel_by_tparty_and_keyword(channel_keyword, revised_message) if !response
    else
      response = find_matching_channel_group_by_tparty(revised_message) if !response
      response = find_matching_channel_by_tparty(revised_message) if !response
    end
    response = [nil,nil,nil,message.join(' ')] if !response
    response
  end

  def self.find_matching_channel_group_by_tparty_and_keyword(channel_keyword, message)
    cg = ChannelGroup.by_tparty_keyword(message[0]).by_keyword(channel_keyword).try(:first)
    if cg
      tkw = message.shift
      kw = message.shift
      mes = message.join(' ')
      [cg, tkw, kw, mes]
    else
      false
    end
  end

  def self.find_matching_channel_group_by_tparty(message)
    resp = false
    if ChannelGroup.by_tparty_keyword(message[0]).count == 1
      cg = ChannelGroup.by_tparty_keyword(message[0]).try(:first)
      if cg
        tkw = message.shift
        kw = nil
        mes = message.join(' ')
        resp = [cg, tkw, kw, mes]
      end
    end
    resp
  end

  def self.find_matching_channel_by_tparty_and_keyword(channel_keyword, message)
    chn = Channel.by_tparty_keyword(message[0]).by_keyword(channel_keyword).try(:first)
    if chn
      tkw = message.shift
      kw = message.shift
      mes = message.join(' ')
      [chn, tkw, kw, mes]
    else
      false
    end
  end

  # retruns a cahnnel ,if there is only 1 channel that has this tparty identifier
  def self.find_matching_channel_by_tparty(message)
    resp = false
    if Channel.by_tparty_keyword(message[0]).count == 1
      chn = Channel.by_tparty_keyword(message[0]).try(:first)
      if chn
        tkw = message.shift
        kw = nil
        mes = message.join(' ')
        resp = [chn, tkw, kw, mes]
      end
    end
    resp
  end
  # matches the keyword to the channel, by handling cases where there is
  # a space in the keyword. Returns a revised message array with the
  #
  def self.channel_keyword_match(message)
    # puts "Original Message: #{message}"
    potential_keywords = potential_matching_keywords(message[0])
    final_message = message
    match_string = message.drop(1).join # drops tparty_identifier, joins all the rest of the text, leaving message unmodified
    matched_keyword = nil
    Array(potential_keywords).each do |pk|
      if match_string.start_with?(pk)
        matched_keyword = pk
        # get the start and ending index, so we can merge them together
        # so the revised array has the keyword correctly in it
        revised_message = []
        message.each do |x|
          if x.include?(pk)
            revised_message << pk
            remainder = x.gsub(pk, '')
            revised_message << remainder unless remainder.blank?
          else
            revised_message << x
          end
        end
        # puts "Revised Message: #{revised_message}"
        # get the start and ending index, so we can merge them together
        # so the revised array has the keyword correctly in it
        index_start = revised_message.index { |str| matched_keyword.scan(/^#{Regexp.quote(str)}/i).length == 1 }
        index_end   = revised_message.index { |str| matched_keyword.scan(/#{Regexp.quote(str)}$/i).length == 1 }
        indexes_to_delete = (index_start..index_end).to_a if index_start && index_end
        if indexes_to_delete
          final_message = revised_message.delete_if.with_index { |item, indx| indexes_to_delete.include?(indx) }
          final_message.insert(index_start, matched_keyword)
        end
        # puts "Final Message: #{final_message}"
        break
      end
    end
    [matched_keyword, final_message]
  end

  def parse_message
    ::SubscriberResponse.parse_message(caption, tparty_identifier)
  end

  def sra
    SubscriberResponseAssociator.new(self)
  end

  def sra_recommendation
    sra.recommendation
  end

  # this is where the logic for matching up to a channel and a subscriber are
  def assign_channel_and_subscriber
    target_channel, t_tparty_keyword, t_keyword, t_message = parse_message
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

  def assign_subscriber_from_phone_number
    return true if self.subscriber_id
    flag = false
    if Subscriber.where(phone_number: origin).order(created_at: :desc).count == 1
      subscriber = Subscriber.where(phone_number: origin).order(created_at: :desc).first
      if subscriber
        subscriber.subscriber_responses << self
        self.reload
        flag = true
      else
        update_processing_log('Unable to find subscriber for SRA processing.')
      end
    end
    flag
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

  def try_processing_with_target_channel
    flag = false
    if target
      if target.process_subscriber_response(self)
        flag = true
      else
        update_processing_log('Processing subscriber response by channel returned false')
      end
    else
      update_processing_log('Target channel not found.')
    end
    flag
  end

  # this is UGGGGLY
  def try_processing_with_sra
    flag = false
    resp = assign_subscriber_from_phone_number
    if resp
      self.save
      self.reload
      sra_recs = sra_recommendation
      if sra_recs
        self.channel_id = sra_recs[:channel_id] unless self.channel_id
        self.message_id = sra_recs[:message_id] unless self.message_id
      end
    end
    self.save
    self.reload
    if self.channel_id
      channel = Channel.find(self.channel_id)
      flag =  channel.process_subscriber_response(self)
    end
    flag = true if self.channel_id
    flag
  end

  def try_processing
    flag = false
    flag = try_processing_with_target_channel
    flag = try_processing_with_sra if flag == false
    if flag == true
      self.processed = true
    end
    save
    flag
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
