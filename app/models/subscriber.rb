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
  acts_as_paranoid
  attr_accessible :name, :phone_number, :remarks, :email, :additional_attributes

  belongs_to :user
  has_many :subscriptions
  has_many :channels, :through => :subscriptions
  has_many :delivery_notices
  has_many :subscriber_responses

  validates :phone_number, presence:true, phone_number:true,
    uniqueness:{scope:[:user_id,:deleted_at]}
  validates :email, format: {with:/\A.+@.+\z/}, allow_blank:true

  before_validation :normalize_phone_number

  def self.find_by_phone_number(phone_number)
    ref_phone_number = Subscriber.format_phone_number(phone_number)
    where(phone_number:ref_phone_number).first
  end

  def custom_attributes
    @supplied_attributes ||= begin
      sa = {}
      additional_attributes.to_s.split(";").each do |item|
        key, value = item.to_s.split("=", 2)
        key.downcase!
        sa[key] = value
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
