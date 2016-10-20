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

  def group_subscribers_by_message
    #Find those messages which have not been sent and whose next_send_time
    #is in the past
    if !relative_schedule
      subscriber_ids = subscribers.map(&:id)
      message_ids = messages.active.pending_send.select(:id).map(&:id)
      if message_ids.length > 0
        msh = {}
        message_ids.each do |message_id|
          subscriber_ids.each do |subscriber_id|
            next if DeliveryNotice.of_primary_messages.where(message_id:message_id,subscriber_id:subscriber_id).first
            if msh[message_id]
              msh[message_id] << Subscriber.find(subscriber_id)
            else
              msh[message_id] = [Subscriber.find(subscriber_id)]
            end
          end
        end
        return msh
      else
        return nil
      end
    else
      subscriber_ids = subscribers.map(&:id)
      #For each message
      msh={}
      messages.active.each do |message|
        message_id = message.id
        #For all subscribers
        subscriber_ids.each do |subscriber_id|
          #check if they have been sent the message
          next if DeliveryNotice.of_primary_messages.where(message_id:message_id,subscriber_id:subscriber_id).first
          #If the message schedule since the subscriber addition is in past
          subscriber_added_time = Subscription.where(subscriber_id:subscriber_id,channel_id:self.to_param).first.created_at
          if message.target_time(subscriber_added_time) < Time.now
            #include such message
            if msh[message_id]
              msh[message_id] << Subscriber.find(subscriber_id)
            else
              msh[message_id] = [Subscriber.find(subscriber_id)]
            end
          end
        end
      end
      return msh
    end
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

  def reset_next_send_time
    #Since the channel does not have a schedule, but still we need to
    #be able to send pending messages, set the next send time as now.
    #Probably it can be optimised to use the nearest of the messages next_send_time
    #but it needs to be kept updated etc.
    self.next_send_time = Time.now
  end

  def after_subscriber_add_callback(subscriber)
    #If the subscriber was subscribed before, we need to restart from the previous message. We use a hack here by modifying the subscription creation date.
    psent_messages_schedules = []
    DeliveryNotice.of_primary_messages.where(channel_id:id,subscriber_id:subscriber.id).each do |dn|
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
