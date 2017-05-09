require 'spec_helper'

describe ScheduleCalculator do
  # , 'Minute 15', 'Minute 120'
  it 'handles minutes' do
    [['Minute 1', 1.minute], ['Minute 120', 120.minutes]].each do |min_str, min_dur|
      now = Time.now
      helper = ScheduleCalculator.new(now, min_str)
      expect(helper.schedule).to be_within(1.second).of(now + min_dur)
    end
  end

  it 'handles hours' do
    [['Hour 1', 1.hour], ['Hour 2', 2.hours], ['hour 10', 10.hours]].each do |hour_str, hour_dur|
      now = Time.now
      helper = ScheduleCalculator.new(now, hour_str)
      expect(helper.schedule).to be_within(2.seconds).of(now + hour_dur)
    end
  end

  it 'handles days' do
    [
      ['Day 1 8:00', '2016-11-07 08:00:00 -0500'],
      ['Day 25 17:00', '2016-12-01 17:00:00 -0500']
    ].each do |day_str, day_result_str|
      now = Chronic.parse('November 6, 2016 at 15:00:00')
      helper = ScheduleCalculator.new(now, day_str)
      expect(helper.schedule).to be_within(10.seconds).of(Time.parse(day_result_str))
    end
  end

  it 'handles weeks' do
    [
      ['Week 4 Tuesday 15:00', '2016-12-05 15:00:00 -0500'],
      ['Week 1 Thursday 8:0', '2016-11-16 08:00:00 -0500']
    ].each do |week_str, week_result_str|
      now = Chronic.parse('November 6, 2016 at 15:00:00')
      helper = ScheduleCalculator.new(now, week_str)
      expect(helper.schedule).to be_within(10.seconds).of(Time.parse(week_result_str))
    end
  end

end
