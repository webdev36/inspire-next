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

class RandomMessagesChannel < Channel

  def self.system_channel?
    false
  end


  def has_schedule?
    true
  end

  #Defines whether the move-up and move-down actions make any sense
  def sequenced?
    false
  end

  def broadcastable?
   false
  end

  def type_abbr
    "Random"
  end

  def individual_messages_have_schedule?
    false
  end

  def group_subscribers_by_message
    msh = {}
    subscribers.each do |subscriber|
      pending_messages = pending_messages_ids(subscriber)
      if pending_messages.empty? && !send_only_once
        pending_messages = messages.select(:id).map(&:id)
      end
      random_message = pending_messages.sample
      if random_message
        if msh[random_message]
          msh[random_message] << subscriber
        else
          msh[random_message] = [subscriber]
        end
        StatsD.increment("subscriber.#{subscriber.id}.message.#{random_message}.queued")
      end
    end
    msh
  end
end
