module RelativeSchedule

  NEVER = Time.now + 1.year

  attr_writer :relative_schedule_type,:relative_schedule_number,
    :relative_schedule_day,:relative_schedule_hour,:relative_schedule_minute

  def schedule_errors
    case relative_schedule_type
    when 'Minute'
      return[:relative_schedule_number,'must have a positive value'] if relative_schedule_number.to_i <=0
    when 'Hour'
      return[:relative_schedule_number,'must have a positive value'] if relative_schedule_number.to_i <=0
      return[:relative_schedule_minute,'must be a valid minute'] if relative_schedule_minute.to_i <0 || relative_schedule_minute.to_i >59
    when 'Day'
      return[:relative_schedule_number,'must have a positive value'] if relative_schedule_number.to_i <=0
      return[:relative_schedule_hour,'must have a value between 0 & 23'] if relative_schedule_hour.to_i <0 || relative_schedule_hour.to_i >23
      return[:relative_schedule_minute,'must be a valid minute'] if relative_schedule_minute.to_i <0 || relative_schedule_minute.to_i >59
    when 'Week'
      return[:relative_schedule_number,'must have a valid value'] if relative_schedule_number.to_i <=0
      if !(['sunday','monday','tuesday','wednesday','thursday','friday','saturday'].include?(relative_schedule_day.downcase))
        return[:relative_schedule_day,'must have a day of week']
      end
      return[:relative_schedule_hour,'must have a value between 0 & 23'] if relative_schedule_hour.to_i <0 || relative_schedule_hour.to_i >23
      return[:relative_schedule_minute,'must be a valid minute'] if relative_schedule_minute.to_i <0 || relative_schedule_minute.to_i >59
    else
      return[:relative_schedule_type,"must be one of minute,hour,day,week"]
    end
    return [nil,nil]
  end

  def relative_schedule_type
    @relative_schedule_type || get_field_from_schedule_text(:relative_schedule_type)
  end

  def relative_schedule_number
    @relative_schedule_number || get_field_from_schedule_text(:relative_schedule_number)
  end

  def relative_schedule_day
    @relative_schedule_day || get_field_from_schedule_text(:relative_schedule_day)
  end

  def relative_schedule_hour
    @relative_schedule_hour || get_field_from_schedule_text(:relative_schedule_hour)
  end

  def relative_schedule_minute
    @relative_schedule_minute || get_field_from_schedule_text(:relative_schedule_minute)
  end

  def get_field_from_schedule_text(field)
    return nil if schedule.blank?
    tokens = schedule.split
    return nil if tokens.length < 2
    case tokens[0]
    when 'Minute'
      md = schedule.match(/^Minute (\d+)$/)
      return nil if (!md || !md[1])
      case field
      when :relative_schedule_type
        'Minute'
      when :relative_schedule_number
        md[1] rescue nil
      else
        nil
      end
    when 'Hour'
      md = schedule.match(/^Hour (\d+) (\d+)$/)
      return nil if (!md || !md[1] || !md[2])
      case field
      when :relative_schedule_type
        'Hour'
      when :relative_schedule_number
        md[1] rescue nil
      when :relative_schedule_minute
        md[2] rescue nil
      else
        nil
      end
    when 'Day'
      md = schedule.match(/^Day (\d+) (\d+):(\d+)$/)
      return nil if (!md || !md[1] || !md[2] || !md[3])
      case field
      when :relative_schedule_type
        'Day'
      when :relative_schedule_number
        md[1] rescue nil
      when :relative_schedule_hour
        md[2]rescue nil
      when :relative_schedule_minute
        md[3] rescue nil
      else
        nil
      end
    when 'Week'
      md = schedule.match(/^Week (\d+) (\S+) (\d+):(\d+)$/)
      return nil if (!md || !md[1] || !md[2] || !md[3] || !md[4])
      case field
      when :relative_schedule_type
        'Week'
      when :relative_schedule_number
        md[1] rescue nil
      when :relative_schedule_day
        md[2]
      when :relative_schedule_hour
        md[3] rescue nil
      when :relative_schedule_minute
        md[4] rescue nil
      else
        nil
      end
    else
      return nil
    end
  end

  def form_schedule
    self.schedule = schedule_text
  end

  def schedule_text
    case relative_schedule_type
    when 'Minute'
      "Minute #{relative_schedule_number}"
    when 'Hour'
      "Hour #{relative_schedule_number} #{relative_schedule_minute}"
    when 'Day'
      "Day #{relative_schedule_number} #{relative_schedule_hour}:#{relative_schedule_minute}"
    when 'Week'
      "Week #{relative_schedule_number} #{relative_schedule_day} #{relative_schedule_hour}:#{relative_schedule_minute}"
    else
      nil
    end
  end

  def get_wday(str)
    case str
    when 'Sunday'
      0
    when 'Monday'
      1
    when 'Tuesday'
      2
    when 'Wednesday'
      3
    when 'Thursday'
      4
    when 'Friday'
      5
    when 'Saturday'
      6
    else
      0
    end
  end

  def target_time(from_time = Time.now)
    return NEVER if schedule.blank?
    tokens = schedule.split
    return NEVER if tokens.length < 2
    case tokens[0]
    when 'Minute'
      md = schedule.match(/^Minute (\d+)$/)
      return NEVER if (!md || !md[1])
      minutes_from_now = md[1].to_i rescue 0
      return from_time+(60*minutes_from_now)
    when 'Hour'
      md = schedule.match(/^Hour (\d+) (\d+)$/)
      return NEVER if (!md || !md[1] || !md[2])
      # There is an error in the calculation for time that is in past.
      # The fix in 291aef7dc309db7b4dca00d08cf7f2413e8844d1 solves it.
      # But it creates some unreliable user scenarios if we have hourly messages
      # configured at different times.
      hours_from_now = (md[1].to_i)-1 rescue 0
      epoch = (from_time+hours_from_now.hours).beginning_of_hour
      return Chronic.parse("#{md[2]} minutes from now",now:epoch)
    when 'Day'
      md = schedule.match(/^Day (\d+) (\d+):(\d+)$/)
      return NEVER if (!md || !md[1] || !md[2] || !md[3])
      # There is an error in the calculation for time that is in past.
      # The fix in 291aef7dc309db7b4dca00d08cf7f2413e8844d1 solves it.
      # But it creates some unreliable user scenarios if we have daily messages
      # configured at different times.
      days_from_now = (md[1].to_i)-1 rescue 0
      if days_from_now == 0
        epoch = from_time
      else
        epoch = (from_time+days_from_now.days).beginning_of_day
      end
      return Chronic.parse("#{md[2]}:#{md[3]}",now:epoch)
    when 'Week'
      md = schedule.match(/^Week (\d+) (\S+) (\d+):(\d+)$/)
      return NEVER if (!md || !md[1] || !md[2] || !md[3] || !md[4])
      weeks_from_now = (md[1].to_i)-1 rescue 0
      wday = get_wday(md[2])
      if wday > from_time.wday
        epoch = (from_time+weeks_from_now.weeks).beginning_of_day
      elsif wday == from_time.wday
        if from_time.hour > md[3].to_i
          epoch = (from_time+weeks_from_now.weeks).beginning_of_day
        elsif from_time.hour == md[3].to_i
          if from_time.min >= md[4].to_i
            epoch = (from_time+weeks_from_now.weeks).beginning_of_day
          else
            epoch = (from_time+weeks_from_now.weeks).beginning_of_day-1
          end
        else
          epoch = (from_time+weeks_from_now.weeks).beginning_of_day-1
        end
      else
        epoch = (from_time+weeks_from_now.weeks).beginning_of_day-1
      end

      scheduled_time = Chronic.parse("#{md[2]} #{md[3]}:#{md[4]}",now:epoch)
      #Chronic does not handle past time well in case of week schedules.
      if scheduled_time < from_time
        scheduled_time= scheduled_time+1.week
      end
      return scheduled_time
    else
      return NEVER
    end
  end

  #This method returns time such that the message will be due for sending soon.
  #This is used to reset the subscription time in order to ensure a subscriber
  #returning back to a channel starts receiving messages post the last received one.
  def reverse_engineer_target_time(from_time = Time.now)
    return from_time if schedule.blank?
    tokens = schedule.split
    return from_time if tokens.length < 2
    case tokens[0]
    when 'Minute'
      md = schedule.match(/^Minute (\d+)$/)
      return from_time if (!md || !md[1])
      minutes_from_now = md[1].to_i rescue 0
      return from_time-(60*(minutes_from_now+1))
    when 'Hour'
      md = schedule.match(/^Hour (\d+) (\d+)$/)
      return from_time if (!md || !md[1] || !md[2])
      hours_from_now = (md[1].to_i) rescue 0
      epoch = (from_time-hours_from_now.hours).beginning_of_hour
      return Chronic.parse("#{md[2]} minutes before now",now:epoch)-1.minute
    when 'Day'
      md = schedule.match(/^Day (\d+) (\d+):(\d+)$/)
      return from_time if (!md || !md[1] || !md[2] || !md[3])
      days_from_now = (md[1].to_i) rescue 0
      if days_from_now == 0
        epoch = from_time
      else
        epoch = (from_time-days_from_now.days).beginning_of_day
      end
      return epoch
    when 'Week'
      md = schedule.match(/^Week (\d+) (\S+) (\d+):(\d+)$/)
      return from_time if (!md || !md[1] || !md[2] || !md[3] || !md[4])
      weeks_from_now = (md[1].to_i) rescue 0
      epoch = (from_time-weeks_from_now.weeks).beginning_of_day
      # scheduled_time = Chronic.parse("#{md[2]} #{md[3]}:#{md[4]}",now:epoch)
      # #Chronic does not handle past time well in case of week schedules.
      # if scheduled_time > from_time
      #   scheduled_time= scheduled_time-1.week
      # end
      return epoch
    else
      return from_time
    end
  end
end
