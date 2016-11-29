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
  include RecurringScheduler

  attr_accessible :title, :caption, :type, :content,
    :next_send_time,:reminder_message_text, :reminder_delay,
    :repeat_reminder_message_text, :repeat_reminder_delay,
    :number_of_repeat_reminders, :action_attributes, :schedule,
    :relative_schedule_type, :relative_schedule_number,
    :relative_schedule_day, :relative_schedule_hour,
    :relative_schedule_minute, :active, :message_options_attributes,
    :recurring_schedule

  serialize :options, Hash
  serialize :recurring_schedule, Hash

  has_many :delivery_notices
  has_many :subscriber_responses
  has_one  :action, as: :actionable
  has_many :response_actions
  has_many :message_options

  accepts_nested_attributes_for :message_options, :reject_if => lambda { |a| a[:key].blank? || a[:value].blank? }, :allow_destroy => true

  has_attached_file :content,
                     storage: :s3,
                     s3_credentials: {
                        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
                        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
                     },
                     s3_region: ENV["AWS_REGION"],
                     styles: {
                        thumb: { geometry: "100x100>", format: "jpg" },
                     }

  belongs_to :channel

  validates  :seq_no, uniqueness:{scope: [:channel_id,:deleted_at]}

  before_create :update_seq_no
  after_create  :aftr_create_cb

  before_validation :form_schedule
  validate          :check_relative_schedule

  scope :search,   -> (search)  { where('lower(title) LIKE ? OR lower(caption) LIKE ? OR lower(reminder_message_text) LIKE ? OR lower(repeat_reminder_message_text) like ?',"%#{search.to_s.downcase}%", "%#{search.to_s.downcase}%", "%#{search.to_s.downcase}%", "%#{search.to_s.downcase}%") }

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

  scope :primary,      -> { where( primary: true )          }
  scope :secondary,    -> { where( primary:false)           }
  scope :active,       -> { where( active: true)            }
  scope :in_seq_order, -> { order("seq_no ASC NULLS LAST")  }

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
    where(active:true).in_seq_order.where("next_send_time <= (?)",Time.now )
  end

  def reset_next_send_time
    self.next_send_time = Time.now
    save!
  end

  def broadcast
    MessagingManagerWorker.perform_async('broadcast_message',
      {'message_id'=>id})
  end

  def set_seq_position(new_position)
    new_position = new_position.to_i
    potential_move_maximum = self.channel.messages.count
    count_moves = 0
    return false if potential_move_maximum > 300
    until (seq_no == new_position) || (count_moves >= potential_move_maximum)
      puts "seq_no #{seq_no} new_position: #{new_position}"
      move_down if seq_no < new_position
      move_up if seq_no > new_position
      count_moves += 1
      self.reload
    end
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
    srs = subscriber_responses.order('created_at DESC')
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
    #retval.sort!{|x,y| x[:message_content]<=>y[:message_content]}
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
        if message.type == 'TagMessage'
          csv << message.message_options.column_names
          message.message_options.each do |message_tag|
            csv << message_tag.attributes.values_at("id","message_id","key","value","created_at","updated_at")
          end
          csv << ["*******"]
        end
      end
    end
  end

  def self.import(channel, file)
    error_message = nil
    csv_string = File.read(file.path).scrub
    error_rows = []
    count_rows = 0
    CSV.parse(csv_string, headers:true) do |row|
      count_rows += 1
      begin
        message = channel.messages.find_by_id(row["id"]) || channel.messages.new
        hash_row = row.to_h
        hash_row['seq_no'] = nil
        hash_row.keys.each do |key|
          hash_row[key] = {} if hash_row[key] == '{}'
          message[key] = hash_row[key] unless ["options"].include?(key)
        end
        message.channel_id = channel.id
        message.created_at = Time.current
        message.updated_at = Time.current
        message.form_schedule
        if message.save
          next
        else
          error_rows << row.to_h
        end
      rescue => e
        error_rows << row.to_h
      end
    end
    if error_rows.length > 0
      { completed: true, message: "Import completed with #{error_rows.count} import failures", error_rows: error_rows }
    else
      { completed: true, message: nil, error_rows: error_rows }
    end
    rescue => e
      { completed: false, message: e.message, error_rows: error_rows }
    end


    def handle_subscriber_response_error(subscriber_response, error_type, action)
      StatsD.increment("message.#{self.id}.subscriber_response.#{subscriber_response.id}.#{error_type.underscore}")
      Rails.logger.error "error=#{error_type.underscore} subscriber_response_id=#{subscriber_response.id} message_id=#{self.id}"
      subscriber_response.update_processing_log("#{action.titleize} command: #{error_type}")
    end

    def handle_subscriber_response_success(subscriber_response, info_type, action)
      StatsD.increment("message.#{self.id}.subscriber_response.#{subscriber_response.id}.#{info_type.underscore}")
      Rails.logger.info "info=#{info_type.underscore} subscriber_response_id=#{subscriber_response.id} message_id=#{self.id}"
      subscriber_response.update_processing_log("#{action.titleize} command: #{info_type}")
    end

private

  def update_seq_no
    cur_max = channel.messages.maximum(:seq_no) rescue 0
    cur_max = 0 if cur_max.nil?
    self.seq_no = cur_max+1
  end

  # def after_create_actions
  #   self.reload
  #   self.requires_response = self.requires_user_response?
  #   # self.next_send_time = 1.minute.ago if channel.individual_messages_have_schedule?
  #   self.save if self.changed?
  #   self.channel.save!
  # end

  def aftr_create_cb
    msg = Message.find(id) #Update the requires_response based on type
    msg.update_attribute(:requires_response, msg.requires_user_response?)
    channel.save! #This is required so that the channel's update_send_time is reliably called
  end
#
  # def set_next_send_time
  #   if channel.individual_messages_have_schedule?
  #     self.update_attribute(:next_send_time, 1.minute.ago)
  #     self.channel.self.next_send_time = 1.minute.ago
  #     channel.save!
  #   end
  # end

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

