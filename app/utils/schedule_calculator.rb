class ScheduleCalculator
  attr_reader :base_time, :str

  def self.to_time(base_time, str)
    helper = new(base_time, str)
    helper.schedule
  end

  def initialize(base_time, str)
    @base_time = base_time
    @str = str.downcase
  end

  def schedule
    case time_type
    when 'minute', 'hour'
      base_calculated_time
    when 'day'
      day_time
    when 'week'
      week_time
    end
  end

  def set_time_of_day(t_object, hr, min)
    Time.local(t_object.year, t_object.month, t_object.day, hour, minute, 0)
  end

  def base_calculated_time
    base_time + duration
  end

  def day_time
    set_time_of_day(base_calculated_time, hour, minute)
  end

  def week_time
    the_right_day = base_calculated_time + days_from_bow
    set_time_of_day(the_right_day, hour, minute)
  end

  # which is a monday
  def base_calculated_time_bow
    base_calculated_time.beginning_of_week
  end

  def duration
    (time_type_amount&.send(time_type))
  end
  # splits the input into tokens, which are then parsed into the
  # appropriate variables for further processing
  def tokens
    @tokens ||= str.split(/\W+/i)
  end

  def time_type
    @time_type ||= tokens.try(:[], 0)
  end

  def time_type_amount
    @time_type_amount ||= tokens.try(:[], 1).try(:to_i)
  end

  def days_from_bow
    %w( monday tuesday wednesday thursday friday saturday sunday ).index(day_of_week).days
  end

  def day_of_week
    @day_of_week ||= begin
      if time_type == 'week'
        tokens.try(:[], 2)
      else
        nil
      end
    end
  end

  def hour
    @hour ||= begin
      if time_type == 'week'
        tokens.try(:[], 3).try(:to_i)
      else
        tokens.try(:[], 2).try(:to_i)
      end
    end
  end

  def minute
    @minute ||= begin
      if time_type == 'week'
        tokens.try(:[], 4).try(:to_i)
      else
        tokens.try(:[], 3).try(:to_i)
      end
    end
  end
end
