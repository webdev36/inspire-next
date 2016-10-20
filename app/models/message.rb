# == Schema Information
#
# Table name: messages
#
#  id                           :integer          not null, primary key
#  title                        :text
#  caption                      :text
#  type                         :string(255)
#  channel_id                   :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  content_file_name            :string(255)
#  content_content_type         :string(255)
#  content_file_size            :integer
#  content_updated_at           :datetime
#  seq_no                       :integer
#  next_send_time               :datetime
#  primary                      :boolean
#  reminder_message_text        :text
#  reminder_delay               :integer
#  repeat_reminder_message_text :text
#  repeat_reminder_delay        :integer
#  number_of_repeat_reminders   :integer
#  options                      :text
#  deleted_at                   :datetime
#  schedule                     :text
#

class Message < ActiveRecord::Base
  acts_as_paranoid
  include RelativeSchedule

  attr_accessible :title, :caption, :type, :content,
    :next_send_time,:reminder_message_text,:reminder_delay,
    :repeat_reminder_message_text, :repeat_reminder_delay,
    :number_of_repeat_reminders,:action_attributes,:schedule,
    :relative_schedule_type,:relative_schedule_number,
    :relative_schedule_day,:relative_schedule_hour,
    :relative_schedule_minute,:active, :message_options_attributes



  serialize :options, Hash

  has_many :delivery_notices
  has_many :subscriber_responses
  has_one :action, as: :actionable
  has_many :response_actions

  has_many :message_options
  accepts_nested_attributes_for :message_options, :reject_if => lambda { |a| a[:key].blank? || a[:value].blank? }, :allow_destroy => true

  has_attached_file :content, :styles => {
    :thumb=> {:geometry=>'100x100>', :format=>'jpg'}
  }

  belongs_to :channel
  validates :seq_no, uniqueness:{scope: [:channel_id,:deleted_at]}

  before_create :update_seq_no
  after_create :aftr_create_cb

  before_validation :form_schedule
  validate :check_relative_schedule

  accepts_nested_attributes_for :action
  validates_associated :action

  after_initialize do |message|
    if message.new_record?
      begin
        message.type ||= 'SimpleMessage'
        message.primary ||= true
        message.reminder_delay ||= 1
        message.repeat_reminder_delay ||= 30
        message.number_of_repeat_reminders ||= 1
        message.active = true if message.active.nil?
        message.requires_response ||= false
      rescue ActiveModel::MissingAttributeError
      end
    end
  end

  scope :primary, where(primary:true)
  scope :secondary, where(primary:false)
  scope :active, where(active:true)

  @child_classes = []

  def self.inherited(child)
    child.instance_eval do
      def model_name
        Message.model_name
      end
    end
    @child_classes << child
    super
  end

  def self.child_classes
    @child_classes
  end

  def self.pending_send
    where(active:true).where("next_send_time <= ?",Time.now )
  end

  def reset_next_send_time
    self.next_send_time = Time.now
    save!
  end


  def broadcast
    MessagingManagerWorker.perform_async('broadcast_message',
      {'message_id'=>id})
  end

  def move_up
    current_seq_no = seq_no
    prev_seq_no = channel.messages.where("seq_no < ?",current_seq_no).maximum(:seq_no)
    if (prev_seq_no)
      prev_message = channel.messages.where("seq_no = ?",prev_seq_no).first
      ActiveRecord::Base.transaction do
        self.seq_no = 0
        save!
        prev_message.seq_no = current_seq_no
        prev_message.save!
        self.seq_no = prev_seq_no
        save!
      end
    end
    true
  end

  def move_down
    current_seq_no = seq_no
    next_seq_no = channel.messages.where("seq_no > ?",current_seq_no).minimum(:seq_no)
    if (next_seq_no)
      next_message = channel.messages.where("seq_no = ?",next_seq_no).first
      ActiveRecord::Base.transaction do
        self.seq_no = 0
        save!
        next_message.seq_no = current_seq_no
        next_message.save!
        self.seq_no = next_seq_no
        save!
      end
    end
    true
  end

  def perform_post_send_ops(subscribers)
    ssmc = SecondaryMessagesChannel.find_by_name("_system_smc")
    unless ssmc
      SecondaryMessagesChannel.create!(name:"_system_smc",tparty_keyword:'_system_smc')
      ssmc = SecondaryMessagesChannel.find_by_name("_system_smc")
    end
    if requires_user_response? && reminder_message_text.present? && reminder_delay > 0
      message_text = reminder_message_text
      message_text += " #{channel.suffix}" if channel.suffix.present?
      reminder_message = ssmc.messages.create(caption:message_text)
      reminder_message.next_send_time = Time.now + reminder_delay*60
      reminder_message.primary = false
      reminder_message.options[:message_id] = id
      reminder_message.options[:channel_id] = channel.id
      reminder_message.options[:subscriber_ids] = subscribers.map(&:id)
      reminder_message.options[:tparty_keyword] = channel.tparty_keyword
      reminder_message.options[:reminder_message] = true
      reminder_message.save!
    end
    if requires_user_response? && repeat_reminder_message_text.present? && repeat_reminder_delay > 0 && number_of_repeat_reminders > 0
      (1..number_of_repeat_reminders).each do |index|
        message_text = repeat_reminder_message_text
        message_text += " #{channel.suffix}" if channel.suffix.present?
        repeat_reminder_message = ssmc.messages.create(caption:message_text)
        repeat_reminder_message.primary = false
        repeat_reminder_message.next_send_time = Time.now + repeat_reminder_delay*index*60
        repeat_reminder_message.options[:message_id] = id
        repeat_reminder_message.options[:channel_id] = channel.id
        repeat_reminder_message.options[:subscriber_ids] = subscribers.map(&:id)
        repeat_reminder_message.options[:tparty_keyword] = channel.tparty_keyword
        repeat_reminder_message.options[:repeat_reminder_message] = true
        repeat_reminder_message.save!
      end
    end
    specialized_post_send_ops(subscribers)
  end

  def grouped_responses
    return [] if subscriber_responses.size < 1
    content_hash = {}
    srs = subscriber_responses.order('created_at ASC')
    srs.each do |sr|
      if content_hash[sr.content_text]
        content_hash[sr.content_text][:subscriber_responses] << sr
        content_hash[sr.content_text][:subscribers] << sr.subscriber
      else
        content_hash[sr.content_text]={:subscriber_responses=>[sr],
          :subscribers=>[sr.subscriber]
        }
      end
    end
    retval=[]
    content_hash.each do |content_message,rec|
      retval << {
        :message_content => content_message,
        :subscriber_responses => rec[:subscriber_responses],
        :subscribers => rec[:subscribers].uniq
      }
    end
    retval.sort!{|x,y| x[:message_content]<=>y[:message_content]}
    retval
  end

  #Abstract methods
  def type_abbr
    raise NotImplementedError
  end

  #Messages that require user to send back a response
  def requires_user_response?
    false
  end

  #Messages that do action on user response
  def has_action_on_user_response?
    false
  end

  #Messages that handle broadcast themselves
  def internal?
    false
  end

  def send_to_subscribers(subscribers)
  end

  def process_subscriber_response(sr)
    true
  end

  def specialized_post_send_ops(subscribers)
  end

  def self.my_csv(poptions={})
    CSV.generate(poptions) do |csv|
      csv << column_names
      all.each do |message|
        csv << message.attributes.values_at(*column_names)
      end
    end
  end

  def self.import(channel,file)
    CSV.foreach(file.path,headers:true) do |row|
      message = channel.messages.find_by_id(row["id"]) || channel.messages.new
      message.attributes = row.to_hash.slice(*accessible_attributes)
      Rails.logger.info message.inspect
      message.save!
    end
  end

private

  def update_seq_no
    cur_max = channel.messages.maximum(:seq_no) rescue 0
    cur_max = 0 if cur_max.nil?
    self.seq_no = cur_max+1
  end

  def aftr_create_cb
    msg = Message.find(id) #Update the requires_response based on type
    msg.update_attribute(:requires_response,msg.requires_user_response?)
    channel.save! #This is required so that the channel's update_send_time is reliably called
  end

  def new_update_seq_no
    seq_no = channel.messages.count
  end

  def check_relative_schedule
    return if !schedule
    field,error = schedule_errors
    return if !field
    errors[field]=error
  end

end
