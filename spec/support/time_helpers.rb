require 'spec_helper'
require 'chronic'

# modify the system to make interacting with time nicer
def travel_to(year, month, day, hour, minute, second)
  t = Time.local(year, month, day, hour, minute, second)
  Timecop.travel(t)
end

def travel_to_string_time(str)
  travel_to_time(Chronic.parse(str))
end

def travel_to_time(ruby_time)
  t = Time.local(ruby_time.year, ruby_time.month, ruby_time.day, ruby_time.hour, ruby_time.min, ruby_time.sec)
  Timecop.travel(t)
end

def travel_to_same_day_at(hour, minute)
  tn = Time.now
  t = Time.local(tn.year, tn.month, tn.day, hour, minute, 0)
  Timecop.travel(t)
end

# this ONLY goes forward.
def date_of_next(day)
  date  = Date.parse(day)
  delta = date > Date.today ? 0 : 7
  date + delta
end

# this only goes forward. If you do it twitce in a row, it will
# jump 2 week forward. Saying it another way, if you are on a monday,
# and you call this method, you will move forward 1 week
def travel_to_next_dow(day_of_week)
  today_as_date = Date.parse(Time.now.to_s)
  target_date = date_of_next(day_of_week)
  target_time = Time.parse(target_date.to_s)
  travel_to_time(target_time)
end

RSpec.configure do |config|
  config.before(:each) do
    Timecop.return
  end
  config.after(:each) do
    Timecop.return
  end
end
