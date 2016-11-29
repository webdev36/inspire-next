# == Schema Information
#
# Table name: subscribers
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  phone_number    :string(255)
#  remarks         :text
#  last_msg_seq_no :integer
#  user_id         :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  email           :string(255)
#  deleted_at      :datetime
#

class Subscriber < ActiveRecord::Base
  include Mixins::ChatNames
  acts_as_paranoid
  attr_accessible :name, :phone_number, :remarks, :email, :additional_attributes

  belongs_to :user
  has_many   :rule_activities, as: :ruleable
  has_many   :subscriptions
  has_many   :channels, :through => :subscriptions
  has_many   :delivery_notices
  has_many   :delivery_error_notices
  has_many   :subscriber_responses
  has_many   :action_notices
  has_many   :chatroom_chatters, as: :chatter
  has_many   :chatrooms, through: :chatroom_chatters, source: :chatter, source_type: 'Subscriber'

  has_many   :chats, as: :chatter, dependent: :destroy

  scope :search, -> (search) { where('lower(name) LIKE ? OR phone_number LIKE ?',"%#{search.to_s.downcase}%","%#{search.to_s.downcase}%") }


  validates :phone_number, presence:true, phone_number:true,
    uniqueness:{scope:[:user_id,:deleted_at]}
  validates :email, format: {with:/\A.+@.+\z/}, allow_blank:true

  before_validation :normalize_phone_number

  def self.in_chatroom(chatroom)
    includes(:chatroom_chatters).where('chatroom_chatters.chatroom_id = ?', chatroom.id).references(:chatroom_chatters)
  end

  def self.find_by_phone_number(phone_number)
    ref_phone_number = Subscriber.format_phone_number(phone_number)
    where(phone_number:ref_phone_number).first
  end

  def self.custom_attributes_counts
    cac = {}
    find_each do |subx|
      subx.additional_attributes.to_s.split(';').each do |item|
        key, value = item.to_s.split("=", 2)
        cac[key] = 0 if cac[key].nil?
        cac[key] += 1
      end
    end
    cac
  end

  def custom_attributes
    @custom_attributes ||= begin
      sa = {}
      additional_attributes.to_s.split(";").each do |item|
        key, value = item.to_s.split("=", 2)
        key.downcase!
        sa[key] = value
        # try to convert it to a time or an integer
        time_value = Chronic.parse(value)
        int_value = value.to_i
        sa[key] = time_value if time_value
        sa[key] = int_value if sa[key].nil? && int_value != 0
      end
      sa
    end
  end

  def has_custom_attributes?
    if custom_attributes && custom_attributes.is_a?(Hash) && custom_attributes.keys.length > 0
      true
    else
      false
    end
  end

  def has_replied_to_message?(message)
    SubscriberResponse.where(subscriber_id: self.id, message_id: message.id).count > 0
  end

  def update_custom_attribute(key, val)
    custom_attributes[key.downcase] = val
    save_custom_attributes
  end

  def save_custom_attributes
    self.additional_attributes = ''
    custom_attributes.each_pair do |key, value|
      save_key = key.to_s.downcase
      self.additional_attributes << "#{save_key}=#{value.to_s};"
    end
    self.additional_attributes
    self.save if self.changed?
  end

  private

  def normalize_phone_number
    self.phone_number = Subscriber.format_phone_number(phone_number)
  end

  def self.format_phone_number(phone_number)
    return '' if phone_number.nil?
    return '' if phone_number.blank?
    digits = phone_number.gsub(/\D/,'').split(//)
    return nil if digits.length < 10 || digits.length > 11
    return "+1#{digits.join}" if digits.length == 10
    return "+#{digits.join}" if digits.length == 11
  end

end
