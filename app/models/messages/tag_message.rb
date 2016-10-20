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

class TagMessage < Message

  def self.user_accessible_message_type?
    true
  end

  def type_abbr
    'Tag'
  end

  def caption_for(subscriber)
    if subscriber.has_custom_attributes? && message_text?(subscriber)
      keys = self.matching_message_options(subscriber)
      candidate_msgs = self.message_options.select{|mo| keys.include?(mo[:key])}.map(&:value)
      sent_msgs = DeliveryNotice.where(subscriber_id:subscriber.id).where("caption in (?)",candidate_msgs).map(&:caption)
      remaining_msgs = candidate_msgs-sent_msgs
      if(remaining_msgs.length > 0)
        return remaining_msgs.sample
      else
        return candidate_msgs.sample
      end
    else
      false
    end
  end

  def message_text?(subscriber)
    matching_message_options(subscriber).length > 0
  end

  def matching_message_options(subscriber)
    common_keys=[]
    subscriber.custom_attributes.keys.each do |skey|
      common_keys += message_option_keys.select{|mkey| mkey.downcase==skey.downcase}
    end
    common_keys
  end

  def message_option_keys
    @message_option_keys ||= self.message_options.all.map {|x| x.key }
  end
end
