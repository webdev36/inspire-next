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


class ScheduledMessagesChannel < Channel

  SENT_MESSAGE_MARKER = 1_000_000

  def self.system_channel?
    false
  end


  def has_schedule?
    true
  end

  #Defines whether the move-up and move-down actions make any sense
  def sequenced?
    true
  end

  def broadcastable?
    false
  end

  def type_abbr
    "Scheduled"
  end

  def individual_messages_have_schedule?
    false
  end

  def group_subscribers_by_message
    message = messages.active.where("seq_no < ?",SENT_MESSAGE_MARKER).order('seq_no asc').first
    if message
      subscribers.to_a.each do |sub|
        StatsD.increment("subscriber.#{sub.id}.message.#{message.id}.queued")
      end
      { message.id => subscribers.to_a }
    else
      nil
    end
  end

  def perform_post_send_ops(msg_no_subs_hash)
    if msg_no_subs_hash && msg_no_subs_hash.first
      message_id,subscribers = msg_no_subs_hash.first
      message = Message.find_by_id(message_id)
      if message
        last_sent_message = messages.where("seq_no > ?",SENT_MESSAGE_MARKER).order('seq_no desc').first
        if last_sent_message
          message.update_attribute(:seq_no,last_sent_message.seq_no+1)
        else
          message.update_attribute(:seq_no,SENT_MESSAGE_MARKER+1)
        end
      end
    end
  end

end
