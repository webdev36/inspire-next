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
# NOTES
# Individually scheduled messages channels use a different scheduling system
# based on what the message itself says to do. So, bascially, the channel
# iterates over all mesasges in the cahnnel whenever the cron calls  it to
# see if anything needs to be sent.
#
# A channel can be setup with a "relative schedule", which means dates for
# sending are calculated relative to when the subscriber was added to the
# channel. They can also be "not_relateive_schedule" which means that times
# are calculated relative to the channel's view of time.
#
# Practically, waht this means, is that when you schedule a message in a
# channel:
#   If relatively shceduled (on subscriber time):
#      They are sceduled one time at Day 1 8:00, Week 4 Monday 14:00, or
#      they are schedulee recurring using the reucrring_schedule object
#   if they are static scheduled (on channel time)
#      They are scheduled at a fixed date and time (next_send_at), the
#      schedule and the recurring_scheduled will BOTH be blank.
#      THey are scheduled recurring using the recurring_schedule object
#      taht is stored on the message.


class IndividuallyScheduledMessagesChannel < Channel

  SENT_MESSAGE_MARKER = 1_000_000

  def self.system_channel?
    false
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
    "Ind. Scheduled"
  end

  def individual_messages_have_schedule?
    true
  end

  # Find the messages which have not been sent and whose next_send_time
  # is in the past
  def group_subscribers_by_message
    msh = {}
    messages.each do |message|
      subscribers.each do |subscriber|
        if SendMessageChecker.send_to_subscriber?(subscriber, message)
          msh[message.id] = [] if msh[message.id].blank?
          msh[message.id] << subscriber
        end
      end
    end
    msh
  end

  def perform_post_send_ops(msg_no_subs_hash)
    if !relative_schedule
      if msg_no_subs_hash && msg_no_subs_hash.length > 0
        msg_no_subs_hash.each do |message_no,subscriber|
          msg = Message.find_by_id(message_no)
          if msg
            msg.active=false
            msg.save!
          end
        end
      end
    end
  end

  # Since the channel does not have a schedule, but still we need to
  # be able to send pending messages, set the next send time as now.
  # Probably it can be optimised to use the nearest of the messages next_send_time
  # but it needs to be kept updated etc.
  def reset_next_send_time
    self.next_send_time = Time.now
  end

  def after_subscriber_add_callback(subscriber)
    #If the subscriber was subscribed before, we need to restart from the previous message. We use a hack here by modifying the subscription creation date.
    psent_messages_schedules = []
    DeliveryNotice.of_primary_messages.where(channel_id:id, subscriber_id:subscriber.id).each do |dn|
      msg = Message.find_by_id(dn.message_id)
      psent_messages_schedules << msg.schedule if msg
    end
    if psent_messages_schedules.present?
      reverse_engineered_time = reverse_engineer_subscription_time(psent_messages_schedules)
      if reverse_engineered_time.present?
        subscription = Subscription.where(subscriber_id:subscriber.id,channel_id:self.to_param).first
        if subscription
          subscription.created_at = reverse_engineered_time
          subscription.save!
        end
      end
    end
  end

  def reverse_engineer_subscription_time(delivered_schedules)
    return nil if delivered_schedules.empty?
    curr_time = Time.now
    max_back_track = 1.year.ago
    while curr_time > max_back_track
      all_done = true
      delivered_schedules.each do |pSchedule|
        if find_target_time(pSchedule,curr_time) > Time.now
          all_done=false
          break
        end
      end
      if all_done
        return curr_time
      end
      curr_time -= (3*60*60);
    end
    return nil
  end

  def find_target_time(pSchedule,from_time = Time.now)
    return nil if pSchedule.blank?
    tokens = pSchedule.split
    return nil if tokens.length < 2
    case tokens[0]
    when 'Minute'
      md = pSchedule.match(/^Minute (\d+)$/)
      return nil if (!md || !md[1])
      minutes_from_now = md[1].to_i rescue 0
      return from_time+(60*minutes_from_now)
    when 'Hour'
      md = pSchedule.match(/^Hour (\d+) (\d+)$/)
      return nil if (!md || !md[1] || !md[2])
      hours_from_now = (md[1].to_i)-1 rescue 0
      epoch = (from_time+hours_from_now.hours).beginning_of_hour
      return Chronic.parse("#{md[2]} minutes from now",now:epoch)
    when 'Day'
      md = pSchedule.match(/^Day (\d+) (\d+):(\d+)$/)
      return nil if (!md || !md[1] || !md[2] || !md[3])
      days_from_now = (md[1].to_i)-1 rescue 0
      if days_from_now == 0
        epoch = from_time
      else
        epoch = (from_time+days_from_now.days).beginning_of_day
      end
      return Chronic.parse("#{md[2]}:#{md[3]}",now:epoch)
    when 'Week'
      md = pSchedule.match(/^Week (\d+) (\S+) (\d+):(\d+)$/)
      return nil if (!md || !md[1] || !md[2] || !md[3] || !md[4])
      weeks_from_now = (md[1].to_i)-1 rescue 0
      epoch = (from_time+weeks_from_now.weeks).beginning_of_day-1
      scheduled_time = Chronic.parse("#{md[2]} #{md[3]}:#{md[4]}",now:epoch)
      #Chronic does not handle past time well in case of week schedules.
      if scheduled_time < from_time
        scheduled_time= scheduled_time+1.week
      end
      return scheduled_time
    else
      return nil
    end
  end

end
