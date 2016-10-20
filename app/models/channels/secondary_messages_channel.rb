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

class SecondaryMessagesChannel < Channel

  def self.system_channel?
    true
  end


  def has_schedule?
    false
  end

  #Defines whether the move-up and move-down actions make any sense
  def sequenced?
    false
  end

  def broadcastable?
    false
  end

  def type_abbr
    "Secondary"
  end

  def individual_messages_have_schedule?
    true
  end

  def group_subscribers_by_message
    #Find those messages which have not been sent and whose next_send_time
    #is in the past
    message_ids = messages.pending_send.select(:id).map(&:id)
    if message_ids.length > 0
      msh = {}
      message_ids.each do |message_id|
        message = messages.find_by_id(message_id)
        if message
          msh[message_id]=[]
          subs_ids = message.options[:subscriber_ids]
          orig_message = Message.find(message.options[:message_id]) rescue nil
          subs_ids.each do |subs_id|
            subscriber = Subscriber.find_by_id(subs_id)
            if orig_message && subscriber
              # Find responses for this message from subscribers after this reminder message is created(i.e. when the primary message was sent last)
              if SubscriberResponse.of_subscriber(subscriber).for_message(orig_message).after(message.created_at).count == 0
                msh[message_id] << subscriber
              end
            end
          end
        end
      end
      message_ids.each do |message_id|
        if msh[message_id].nil? || msh[message_id]==[]
          msh.except!(message_id)
          junk = messages.find_by_id(message_id)
          messages.destroy(junk) if junk
        end
      end
      msh
    else
      nil
    end
  end

  def perform_post_send_ops(msg_no_subs_hash)
    msg_no_subs_hash.each do |message_id, subscribers|
      junk = messages.find_by_id(message_id)
      messages.destroy(junk) if junk
    end
  end

end
