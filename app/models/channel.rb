# == Schema Information
#
# Table name: channels
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  user_id           :integer
#  type              :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  keyword           :string(255)
#  tparty_keyword    :string(255)
#  next_send_time    :datetime
#  schedule          :text
#  channel_group_id  :integer
#  one_word          :string(255)
#  suffix            :string(255)
#  moderator_emails  :text
#  real_time_update  :boolean
#  deleted_at        :datetime
#  relative_schedule :boolean
#  send_only_once    :boolean          default(FALSE)
#

class Channel < ActiveRecord::Base
  include ActionView::Helpers
  acts_as_paranoid
  include IceCube
  attr_accessible :description, :name, :type, :keyword, :tparty_keyword,
      :schedule, :channel_group_id, :one_word, :suffix, :moderator_emails,
      :real_time_update,:relative_schedule,:send_only_once,:active,
      :allow_mo_subscription,:mo_subscription_deadline

  belongs_to :user
  belongs_to :channel_group
  has_many :messages, :dependent => :destroy
  has_many :subscriptions
  has_many :subscribers, :through=>:subscriptions,
    :before_add => :check_subscriber_uniqueness,
    :after_add => :after_subscriber_add_callback
  has_many :subscriber_responses

  serialize :schedule, Hash


  validates :name, presence:true, uniqueness:{scope: [:user_id,:deleted_at]}

  validates :type, presence:true, :inclusion=>{:in=>['AnnouncementsChannel',
            'ScheduledMessagesChannel','OrderedMessagesChannel',
            'OnDemandMessagesChannel','RandomMessagesChannel',
            'IndividuallyScheduledMessagesChannel',
            'SecondaryMessagesChannel']}
  validates :keyword, uniqueness:{:scope=>[:tparty_keyword,:deleted_at],
    :case_sensitive=>false,:allow_blank=>true}
  validates :tparty_keyword, presence:true, :tparty_keyword=>true
  validates :one_word,:allow_blank=>true, :one_word=>true, uniqueness:{scope:[:channel_group_id,:deleted_at]}
  validates :moderator_emails, :allow_blank=>true, :emails=>true

  before_create :add_keyword
  before_save :update_next_send_time
  before_destroy :remove_keyword


  after_initialize do |channel|
    if channel.new_record?
      begin
        channel.type ||= 'AnnouncementsChannel'
        if channel.channel_group
          channel.tparty_keyword ||= channel.channel_group.tparty_keyword
        else
          channel.tparty_keyword ||= ENV['TPARTY_PRIMARY_KEYWORD']
        end
        channel.relative_schedule ||= false
      rescue ActiveModel::MissingAttributeError
      end
    end
  end

  #scope :with_subscriber, lambda{|phone_number| includes(:subscribers).where("subscribers.phone_number=?",phone_number)}

  @child_classes = []

  def self.inherited(child)
    child.instance_eval do
      def model_name
        Channel.model_name
      end
    end
    @child_classes << child
    super
  end

  def self.child_classes
    @child_classes
  end

  def send_scheduled_messages
    msg_no_subs_hash = group_subscribers_by_message
    if msg_no_subs_hash && msg_no_subs_hash!={}
      msg_no_subs_hash.each do |msg_no,subscribers|
        message = Message.find_by_id(msg_no)
        if message && message.internal?
          message.send_to_subscribers(subscribers)
        else
          next if subscribers.nil? || subscribers.count == 0
          MessagingManager.new_instance.broadcast_message(message,subscribers)
        end
      end
      perform_post_send_ops(msg_no_subs_hash)
      msg_no_subs_hash.each do |msg_no, subs|
        message = Message.find(msg_no) rescue nil
        message.perform_post_send_ops(subs) if message
      end
    end
    reset_next_send_time
  end

  def group_subscribers_by_message
  end

  def perform_post_send_ops(msg_no_subs_hash)
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

  def self.pending_send
    where("next_send_time <= ?",Time.now )
  end

  def self.active
    where(active:true)
  end

  def self.inactive
    where(active:false)
  end

  def self.with_subscriber(phone_number)
    phone_number = Subscriber.format_phone_number(phone_number)
    includes(:subscribers).where("subscribers.phone_number=?",phone_number).where("subscribers.deleted_at IS NULL")
  end

  def converted_schedule
    sch = read_attribute(:schedule)
    if sch && sch != {}
      the_schedule = Schedule.new(Time.now)
      the_schedule.add_recurrence_rule(RecurringSelect.dirty_hash_to_rule(sch))
      the_schedule
    else
      nil
    end
  end

  def schedule=(new_rule)
    if new_rule != "{}" && RecurringSelect.is_valid_rule?(new_rule)
      write_attribute(:schedule,RecurringSelect.dirty_hash_to_rule(new_rule).to_hash)
    else
      write_attribute(:schedule, nil)
    end
  end

  def reset_next_send_time
    sch = converted_schedule
    if(sch && sch.to_s=="Daily")
      self.next_send_time = (Time.zone.now+1.day).change({hour:rand(9..17),min:rand(0..59)})
    else
      self.next_send_time = sch.next_occurrence(Time.now) if sch
    end
    self.save!
  end

  def get_all_seq_nos
    messages.select(:seq_no).order('seq_no asc').uniq.map(&:seq_no)
  end

  def self.get_next_seq_no(seq_no, seq_nos)
    return nil if (seq_nos.nil? || seq_nos.count < 1)
    return seq_nos[0] if seq_no.nil? || seq_no==0
    matched=false
    seq_nos.each do |curr_no|
      return curr_no if matched
      return curr_no if curr_no > seq_no
      matched=true if curr_no==seq_no
    end
    return nil
  end


  #Defines whether scheduling is relevant for this channel type
  def has_schedule?
    raise NotImplementedError
  end

  #Defines whether the move-up and move-down actions make any sense
  def sequenced?
    raise NotImplementedError
  end

  def broadcastable?
    raise NotImplementedError
  end

  #Give a two character short form for the channel type
  def type_abbr
    raise NotImplementedError
  end

  def individual_messages_have_schedule?
    raise NotImplementedError
  end


  def sent_messages_ids(subscriber)
    message_ids = messages.select(:id).map(&:id)
    subscriber_ids = [subscriber.id]
    DeliveryNotice.where("subscriber_id in (?) and message_id in (?)",subscriber_ids,message_ids).select(:message_id).map(&:message_id)
  end

  def pending_messages_ids(subscriber)
    smi = sent_messages_ids(subscriber)
    if smi == []
      return messages.select(:id).map(&:id)
    else
      return messages.where("id not in (?)",smi).select(:id).map(&:id)
    end
  end

  def process_subscriber_response(subscriber_response)
    command = Channel.identify_command(subscriber_response.content_text)
    case command
    when :start
      process_start_command(subscriber_response)
    when :stop
      process_stop_command(subscriber_response)
    when :custom
      process_custom_command(subscriber_response)
    else
      false
    end
  end

  def process_start_command(subscriber_response)
    if !allow_mo_subscription
      Rails.logger.error("MO Subscription not allowed #{subscriber_response.inspect}")
      return false
    end
    if mo_subscription_deadline.present? && Time.now > mo_subscription_deadline
      Rails.logger.error("MO Subscription expired at #{mo_subscription_deadline} #{subscriber_response.inspect}")
      return false
    end
    phone_number = subscriber_response.origin
    return false if !phone_number
    return true if subscribers.find_by_phone_number(phone_number)

    subscriber = user.subscribers.find_by_phone_number(phone_number)
    if !subscriber
      subscriber = user.subscribers.create!(phone_number:phone_number,name:phone_number)
    end
    subscribers << subscriber
    true
  end

  def process_stop_command(subscriber_response)
    begin
      phone_number = subscriber_response.origin
      return false if phone_number.blank?
      subscriber = subscribers.find_by_phone_number(phone_number)
      return false if !subscriber
      subscribers.delete(subscriber)
      save!
    rescue
      return false
    end
    return true
  end

  def process_custom_command(subscriber_response)
    return true if process_custom_channel_command(subscriber_response)
    message = associate_response_with_last_primary_message(subscriber_response)
    if message
      return message.process_subscriber_response(subscriber_response)
    else
      false
    end
  end

  def process_custom_channel_command(subscriber_response)
    false
  end

  def associate_response_with_last_primary_message(subscriber_response)
    subscriber = subscribers.find_by_phone_number(subscriber_response.origin)
    return false if !subscriber
    dn = subscriber.delivery_notices.of_primary_messages_that_require_response.last
    return false if !dn
    subscriber_response.message = dn.message
    subscriber_response.save
    subscriber_response.message
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

  def messages_report(options={})
    col_names = ['User Name', 'Phone Number','Message','Sent at','Response','Received At']
    CSV.generate(options) do |csv|
      csv << col_names
      subscriber_responses.includes(:subscriber,:message).each do |sr|
        record=[]
        next if sr.subscriber.blank?
        record << sr.subscriber.name
        record << sr.subscriber.phone_number
        record << (sr.message.present? ? sr.message.caption : "")
        record << (sr.message.present? ? sr.message.delivery_notices.where(subscriber_id:sr.subscriber.id).first.created_at : "")
        record << sr.content_text
        record << sr.created_at
        csv << record
      end
    end
  end

  private

  def add_keyword
    if !Channel.find_by_tparty_keyword(tparty_keyword)
      MessagingManagerWorker.perform_async('add_keyword',{'keyword'=>tparty_keyword})
    end
  end

  def remove_keyword
    if Channel.by_tparty_keyword(tparty_keyword).count == 1
      MessagingManagerWorker.perform_async('remove_keyword',{'keyword'=>tparty_keyword})
    end
  end

  def update_next_send_time
    sch = converted_schedule
    if(sch && sch.to_s=="Daily")
      self.next_send_time = (Time.zone.now+1.day).change({hour:rand(9..17),min:rand(0..59)})
    else
      self.next_send_time = sch.next_occurrence(Time.now) if sch
    end
    begin
      self.next_send_time = 1.minute.ago if individual_messages_have_schedule?
    rescue NotImplementedError
    end
  end

  def check_subscriber_uniqueness(subscriber)
    if channel_group
      siblings = channel_group.channels.includes(:subscribers)
      siblings.each do |ch|
        if ch.subscribers.detect{|subs| subs.phone_number == subscriber.phone_number}
          raise ActiveRecord::Rollback, "Subscriber is member of sibling channel"
        end
      end
    end
  end

  def after_subscriber_add_callback(subscriber)
  end

end
