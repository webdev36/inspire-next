# == Schema Information
#
# Table name: channel_groups
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  description        :text
#  user_id            :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  tparty_keyword     :string(255)
#  keyword            :string(255)
#  default_channel_id :integer
#  moderator_emails   :text
#  real_time_update   :boolean
#  deleted_at         :datetime
#

class ChannelGroup < ActiveRecord::Base
  acts_as_paranoid
  attr_accessible :description, :name, :keyword, :tparty_keyword,
                  :default_channel_id, :moderator_emails, :real_time_update,
                  :web_signup

  belongs_to :user
  has_many   :channels, before_add: :check_channel_group_credentials
  belongs_to :default_channel, class_name: 'Channel'
  has_many   :subscriber_responses

  validates  :name, presence: true, uniqueness: { scope: [:user_id,:deleted_at] }
  validates  :keyword, uniqueness: {
                                      :scope=>[:tparty_keyword,:deleted_at],
                                      :case_sensitive=>false,
                                      :allow_blank=>true
                                   }
  validates  :tparty_keyword,   presence:true,     tparty_keyword: true
  validates  :moderator_emails, allow_blank: true, emails: true

  before_create  :add_keyword
  before_destroy :remove_keyword

  scope :search, -> (search) { where('lower(name) LIKE ?',"%#{search.to_s.downcase}%") }

  after_initialize do |channel_group|
    if channel_group.new_record?
      begin
        channel_group.tparty_keyword ||= ENV['TPARTY_PRIMARY_KEYWORD']
      rescue ActiveModel::MissingAttributeError
      end
    end
  end

  def self.find_by_keyword(keyword)
    where("lower(keyword) = ?",keyword.downcase).first
  end

  def self.by_keyword(keyword)
    where("lower(keyword) = ?",keyword.downcase)
  end

  def self.find_by_tparty_keyword(tparty_keyword)
    where("lower(tparty_keyword) = ?",tparty_keyword.downcase).first
  end

  def self.by_tparty_keyword(tparty_keyword)
    where("lower(tparty_keyword) = ?",tparty_keyword.downcase)
  end

  def self.identify_command(message_text)
    return :custom if message_text.blank?
    tokens = message_text.split
    if tokens.length == 1
      case tokens[0]
      when /start/i
        return :start
      when /stop/i
        return :stop
      else
        return :custom
      end
    elsif tokens.length > 1
      return :custom
    end
  end

  def all_channel_subscribers
    channels.includes(:subscribers).map(&:subscribers).flatten
  end

  def process_subscriber_response(subscriber_response)
    command = ChannelGroup.identify_command(subscriber_response.content_text)
    case command
    when :start
      process_start_command(subscriber_response)
    when :stop
      process_stop_command(subscriber_response)
    when :custom
      process_custom_command(subscriber_response)
    else
      handle_channel_group_subscriber_response_error(subscriber_response, 'cannot find a command type', 'command_switch')
      false
    end
  end

  def process_start_command(subscriber_response)
    phone_number = subscriber_response.origin
    if !phone_number || phone_number.blank?
      handle_channel_group_subscriber_response_error(subscriber_response, 'no phone number supplied', 'start')
      return false
    end
    if !default_channel
      handle_channel_group_subscriber_response_error(subscriber_response, 'no default channel', 'start')
      return false
    end
    if channels.with_subscriber(phone_number).size > 0
      handle_channel_group_subscriber_response_error(subscriber_response, 'already in a channel group', 'start')
      return true
    end
    subscriber = user.subscribers.find_by_phone_number(phone_number)
    if !subscriber
      subscriber_response.update_processing_log('New subscriber created due to START command, and no subscriber found.')
      subscriber = user.subscribers.create!(phone_number:phone_number,name:phone_number)
    end
    default_channel.subscribers << subscriber
    handle_channel_group_subscriber_response_success(subscriber_response, 'start command ok', 'start')
    true
  end

  def handle_channel_group_subscriber_response_error(subscriber_response, error_type, action)
    StatsD.increment("channel_group.#{self.id}.subscriber_response.#{subscriber_response.id}.#{action}_command.#{error_type.underscore}")
    Rails.logger.error "error=#{error_type.underscore} subscriber_response_id=#{subscriber_response.id} channel_group_id=#{self.id}"
    subscriber_response.update_processing_log("Rejected #{action} command: #{error_type}")
  end

  def handle_channel_group_subscriber_response_success(subscriber_response, info_type, action)
    StatsD.increment("channel_group.#{self.id}.subscriber_response.#{subscriber_response.id}.#{action}_command.#{info_type.underscore}")
    Rails.logger.info "info=#{info_type.underscore} subscriber_response_id=#{subscriber_response.id} channel_group_id=#{self.id}"
    subscriber_response.update_processing_log("#{action.titleize} command: #{info_type}")
  end

  def process_stop_command(subscriber_response)
    phone_number = subscriber_response.origin
    if phone_number.blank?
      handle_channel_group_subscriber_response_error(subscriber_response, 'no phone number supplied', 'stop')
      return false
    end
    phone_number_subs = {}
    found = false
    channels.with_subscriber(phone_number).each do |ch|
      found = true
      subscribers_to_delete = ch.subscribers.find_by_phone_number(phone_number)
      ch.subscribers.delete(subscribers_to_delete)
      Array(subscribers_to_delete).each do |xsub|
        StatsD.increment("channel.#{ch.id}.subscriber.#{xsub.id}.remove")
        Rails.logger.info "info=remove_from_channel message='Subscriber issued stop command' subscriber_response_id=#{subscriber_response.id} channel_id=#{ch.id} subscriber_id=#{xsub.id}"
        subscriber_response.update_processing_log("Removed subscriber #{xsub.id} from channel #{ch.id} due to stop command.")
      end
    end
    if !found
      handle_channel_group_subscriber_response_error(subscriber_response, 'no channel_found to remove', 'stop')
      return false
    else
      return true
    end
  end

  def process_custom_command(subscriber_response)
    return true if process_on_demand_channels(subscriber_response)
    ch = associate_subscriber_response_with_group_channel(subscriber_response)
    if !ch
      handle_channel_group_subscriber_response_error(subscriber_response, 'channel group association failed', 'custom')
      if !ch
        ch = associate_subscriber_response_with_tparty_channel(subscriber_response)
        if !ch
          handle_channel_group_subscriber_response_error(subscriber_response, 'tparty channel association failed', 'custom')
          return false
        end
      end
    end
    return ask_channel_to_process_subscriber_response(ch,subscriber_response)
  end

  def process_on_demand_channels(subscriber_response)
    msg = subscriber_response.content_text
    if msg.blank?
      handle_channel_group_subscriber_response_error(subscriber_response, 'no subscriber message found', 'on_demand')
      return false
    end
    tokens = msg.split
    if tokens.length != 1
      handle_channel_group_subscriber_response_error(subscriber_response, 'on demand command has more than 1 word', 'on_demand')
      return false
    end
    ch = channels.where(type:'OnDemandMessagesChannel').
      where("lower(one_word) = ? OR lower(keyword) = ?",tokens[0].downcase, tokens[0].downcase).first
    if !ch
      handle_channel_group_subscriber_response_error(subscriber_response, 'on demand command did not match channel', 'on_demand')
      return false
    end
    retval = ch.process_subscriber_response(subscriber_response)
  end

  def associate_subscriber_response_with_group_channel(subscriber_response)
    ch = channels.with_subscriber(subscriber_response.origin).first
    if ch
      subscriber_response.channel = ch
      subscriber_response.channel_group = nil
      subscriber_response.save
    end
    ch
  end

  def associate_subscriber_response_with_tparty_channel(subscriber_response)
    sra = SubscriberResponseAssociator.new(subscriber_response)
    recommendation = sra.recommendation
    if recommendation
      ch = Channel.find(recommendation[:channel_id])
      if ch
        subscriber_response.channel = ch
        subscriber_response.message_id = recommendation[:message_id]
        if ch.channel_group
          subscriber_response.channel_group = ch.channel_group
        end
        subscriber_response.save
      end
    end
    ch
  end

  def ask_channel_to_process_subscriber_response(channel,subscriber_response)
    return channel.process_custom_command(subscriber_response)
  end

  def messages_report(options={})
    col_names = ['User Name', 'Phone Number','Channel','Message','Sent at','Response','Received At']
    CSV.generate(options) do |csv|
      csv << col_names
      subscriber_responses.includes(:subscriber).each do |sr|
        record=[]
        next if sr.subscriber.blank?
        record << sr.subscriber.name
        record << sr.subscriber.phone_number
        record << "" #channel
        record << "" #message
        record << "" #message sent at
        record << sr.content_text
        record << sr.created_at
        csv << record
      end
      channels.each do |ch|
        ch.subscriber_responses.includes(:subscriber,:message).each do |sr|
          record=[]
          next if sr.subscriber.blank?
          record << sr.subscriber.name
          record << sr.subscriber.phone_number
          record << ch.name
          record << (sr.message.present? ? sr.message.caption : "")
          record << (sr.message.present? ? sr.message.delivery_notices.where(subscriber_id:sr.subscriber.id).first.created_at : "")
          record << sr.content_text
          record << sr.created_at
          csv << record
        end
      end
    end
  end

  private

  def check_channel_group_credentials(channel)
    if channel && channel.class != Hash
      raise ActiveRecord::Rollback,"Channel has to be of same user" if (self.channels.count > 0 && channel.user_id != self.channels.first.user_id)
      raise ActiveRecord::Rollback,"Channel is already part of another group" if channel.channel_group && channel.channel_group != self
    end
    true
  end

  def add_keyword
    cg = ChannelGroup.find_by_tparty_keyword(tparty_keyword)
    if !ChannelGroup.find_by_tparty_keyword(tparty_keyword)
      MessagingManagerWorker.perform_async('add_keyword',{'keyword'=>tparty_keyword})
    end
  end

  def remove_keyword
    if tparty_keyword && ChannelGroup.by_tparty_keyword(tparty_keyword).count == 1
      MessagingManagerWorker.perform_async('remove_keyword',{'keyword'=>tparty_keyword})
    end
  end
end




