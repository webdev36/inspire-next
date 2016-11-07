require 'ice_cube'
require 'chronic'

# note that this does NOT go backward in time. It only goes
# forward in time
module RecurringScheduler
  extend ActiveSupport::Concern

  def static_schedule_field
    'schedule'
  end

  def recurring_schedule_field
    'recurring_schedule'
  end

  def recurring_schedule_minimum_distance
    5.minutes
  end

  # provides the next occurance from time now, based on the recurring
  # schedule that has been provided the gem
  def next_occurrence(time_base = Time.now)
    no = nil
    if has_static_schedule_field_data?
      no = language_time(self.send(static_schedule_field), time_base)
    elsif has_recurring_schedule_field_data?
      no =  Time.now if relative_occurrence_right_now?(time_base)
    else # absolute time, only shoudl be run once
      no = next_send_time
    end
    no
  end

  def scheduled_for_now?(time_base = Time.now)
    no = nil
    if has_static_schedule_field_data?
      no = language_time(self.send(static_schedule_field), time_base)
    elsif has_recurring_schedule_field_data?
      no = Time.now if relative_occurrence_right_now?(time_base)
    end
    no
  end

  def local_time_for(time_base)
    Time.local(time_base.year, time_base.month, time_base.day,
                       time_base.hour, time_base.min, time_base.sec)
  end

  # the actual next occurrence calculation. It defaults to now, but can
  # take a time that works for it.
  def relative_next_occurrence(time_base = Time.now)
    recurring_scheduler(time_base).first
  end

  def relative_occurrence_right_now?(time_base = Time.now)
    recurring_scheduler(time_base).occurs_between?(Time.now - 2.minutes, Time.now + 2.minutes)
  end

  # loads an IceCube recurring scheduler that is used to do the calcuations
  # for recurring events. The time_base is what will be used to calculate the
  # next occurrence.
  def recurring_scheduler(time_base = Time.now)
    schedule = IceCube::Schedule.new(time_base) do |s|
      unless self.send(recurring_schedule_field).blank?
        s.add_recurrence_rule(IceCube::Rule.from_hash(self.send(recurring_schedule_field)))
      end
      s
    end
    schedule
  end

  # returns the date relaetive to now, or relative to the base time that is
  # supplied as a ruby object, but does NOT support any recurring times
  def language_time(natural_language_time, time_base = Time.now)
    if matches_static_time?(natural_language_time)
      ScheduleCalculator.to_time(time_base, natural_language_time)
    else
      Chronic.parse(natural_language_time, now: local_time_for(time_base))
    end
  end

  def has_recurring_schedule_field_data?
    !self.send(recurring_schedule_field).blank?
  end

  def has_static_schedule_field_data?
    !self.send(static_schedule_field).blank?
  end

  # parses a string, looking for an interval of time language
  def matches_static_time?(txt)
    !matches_recurring_text?(txt) && txt.scan(/minute|hour|day|month|year/i).length > 0
  end

  # parses a string, looking for an interval of time language
  def matches_recurring_text?(txt)
    txt.scan(/each|every|daily|weekly|monthly|yearly/i).length > 0
  end

end
