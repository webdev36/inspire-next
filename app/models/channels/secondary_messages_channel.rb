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
          msh[message_id] = []
          subs_ids = message.options[:subscriber_ids]
          orig_message = Message.find(message.options[:message_id]) rescue nil
          if subs_ids.blank?
            StatsD.increment("warn_sub_ids_blank")
            Rails.info.logger "info=no_subscriber_ids_found mmessage='No subscribers found in junk message options'"
          end
          subs_ids.each do |subs_id|
            subscriber = Subscriber.find_by_id(subs_id)
            if orig_message && subscriber
              # Find responses for this message from subscribers after this reminder message is created(i.e. when the primary message was sent last)
              if subscriber_has_delivery_notice?(subscriber, orig_message)
                if in_the_reminder_send_window?(subscriber, orig_message)
                  if subscriber_has_not_responded?(subscriber, orig_message, message.created_at)
                    msh[message_id] << subscriber
                    StatsD.increment("subscriber.#{subscriber.id}.message.#{orig_message.id}.queued")
                    Rails.logger.info "info=reminder_message_queued subscriber_id=#{subscriber.id} message_id=#{orig_message.id}"
                  else
                    StatsD.increment("subscriber.#{subscriber.id}.message.#{orig_message.id}.skip_responded")
                    Rails.logger.info "info=reminder_message_skipped subscriber_id=#{subscriber.id} message_id=#{orig_message.id} reason=subscriber_responded"
                  end
                else
                  StatsD.increment("subscriber.#{subscriber.id}.message.#{orig_message.id}.skip_out_of_window")
                  Rails.logger.info "info=reminder_message_skipped subscriber_id=#{subscriber.id} message_id=#{orig_message.id} reason=out_of_reminder_send_window"
                end
              else
                StatsD.increment("subscriber.#{subscriber.id}.message.#{orig_message.id}.skip_not_yet_delivered")
                Rails.logger.info "info=reminder_message_skipped subscriber_id=#{subscriber.id} message_id=#{orig_message.id} reason=message_has_not_been_delivered"
              end
            else
              StatsD.increment("warn_no_orig_message_or_miss_sub")
              Rails.logger.info "info=no_orig_message_or_missing_sub subscriber_id=#{subs_id} original_message_id=#{message.options[:message_id]}"
            end
          end
        else
          StatsD.increment("warn_message_not_found")
          Rails.logger.info "warn=no_message_found message_id=#{message_id} message='No message was found for id #{message_id}'"
        end
      end
      if message_ids.blank?
        StatsD.increment("warn_no_active_messages")
        Rails.logger.info "warn=no_active_messages message='No active messages found when scheduling secondary channel'"
      end
      message_ids.each do |message_id|
        if msh[message_id].nil? || msh[message_id] == []
          msh.except!(message_id)
          junk = messages.find_by_id(message_id)
          if junk
            StatsD.increment('info_remove_temp_message')
            Rails.logger.info "info=removing_temp_message junk_message_id=#{junk.id} original_message_id=#{junk.options[:message_id]} channel_id=#{junk.options[:channel_id]} repeat_reminder_message=#{junk.options[:repeat_reminder_message]} caption='#{junk.caption}'"
            messages.destroy(junk)
          end
        end
      end
      msh
    else
      nil
    end
  end

  def subscriber_has_not_responded?(subscriber, orig_message, created_at)
    SubscriberResponse.of_subscriber(subscriber).for_message(orig_message).after(created_at).count == 0
  end

  def subscriber_has_delivery_notice?(subscriber, orig_message)
    SubscriberMessageSent.delivery_notice_for_message?(subscriber.id, orig_message.id)
  end

  # only deliver reminder messages for messages that are actually in hte delivery window (2x the biggest response at time)
  def in_the_reminder_send_window?(subscriber, orig_message)
    flag = false
    delivered_at = orig_message.delivery_notices.where(:subscriber_id => subscriber.id).try(:first).try(:created_at)
    if delivered_at
      minutes_to_add = delay_window(orig_message)
      last_window_to_deliver = delivered_at + minutes_to_add
      if Time.now < last_window_to_deliver
        flag = true
      end
    end
    flag
  end

  # sets the delay window to greater than 240 minutes..
  def delay_window(msg)
    target_number = [msg.reminder_delay.to_i, msg.repeat_reminder_delay.to_i].try(:compact).try(:sort).try(:last)
    target_number < 120 ? target_number = 120 : target_number
    (target_number * 2).minutes
  end

  def perform_post_send_ops(msg_no_subs_hash)
    msg_no_subs_hash.each do |message_id, subscribers|
      junk = messages.find_by_id(message_id)
      messages.destroy(junk) if junk
    end
  end

end
