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

class OrderedMessagesChannel < Channel

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
    "Ordered"
  end

  def individual_messages_have_schedule?
    false
  end


  def group_subscribers_by_message
    h={}
    seq_nos = get_all_seq_nos
    subscribers.each do |subscriber|
      next_no = Channel.get_next_seq_no(subscriber.last_msg_seq_no,seq_nos)
      if h[next_no]
        h[next_no] << subscriber
      else
        h[next_no] = [subscriber]
      end
    end
    msh = {}
    h.each do |seq_no,subs|
      message = messages.find_by_seq_no(seq_no)
      if message
        msh[message.id] = subs
        subs.each do |sub|
          StatsD.increment("subscriber_id.#{sub.id}.message.#{message.id}.queued")
        end
      end
    end
    msh
  end

  def perform_post_send_ops(msg_no_subs_hash)
    msg_no_subs_hash.each do |msg_no,subs|
      message = Message.find_by_id(msg_no)
      if message
        subs.each do |sub|
          sub.update_attribute(:last_msg_seq_no,message.seq_no)
        end
      end
    end
  end

end
