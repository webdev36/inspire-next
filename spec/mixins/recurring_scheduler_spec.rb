require 'spec_helper'
require 'support/integration_setups'

describe RecurringScheduler do
  let(:helper) {
    class Helper
      attr_accessor :recurring_schedule
      include RecurringScheduler

      def schedule
        nil
      end

      def recurring_schedule
        @recurring_schedule ||= {}
      end
    end
    Helper.new
  }
  let(:static_helper) {
    class Helper
      attr_accessor :recurring_schedule
      include RecurringScheduler

      def schedule
        'Minute 1'
      end

      def recurring_schedule
        @recurring_schedule ||= {}
      end
    end
    Helper.new
  }

  context 'behaves in a production system' do
    it 'that does not error on an empty recurring schedule' do
      expect(helper.recurring_scheduler).to be_a(IceCube::Schedule)
    end
    it 'that does not error on an empty static schedule' do
      expect(helper.schedule.nil?).to be_truthy
    end
  end

  context 'natural language parsing' do
    it 'support natural language parsing of time' do
      expect(helper.language_time('January 21, 2017 at 3pm')).to be_within(5).of(Time.parse("2017-01-21 15:00:00 -0500"))
    end
    it 'supports relative time parsing' do
      expect(helper.language_time('Minute 1', Chronic.parse('January 1, 2000 at 12:00am'))).to eq(Time.parse("2000-01-01 00:01:00 -0500"))
    end
  end

  context 'handles recurring schedules' do
    context 'relative to a supplied date' do
      it 'can provide a time by reading its recurring_schedule field' do
        helper.recurring_schedule = {:validations=>{:day=>[1], :hour_of_day=>[9], :minute_of_hour=>[45]}, :rule_type=>"IceCube::WeeklyRule", :interval=>1, :week_start=>0}
        expect( helper.relative_next_occurrence(Chronic.parse('January 1, 2020')) ).to be_within(5).of(Time.parse("2020-01-06 09:45:00 -0500"))
      end
    end
    context 'relative to now' do
      it 'can provide a time by reading its recurring_schedule field' do
        travel_to_time(Chronic.parse('November 6, 2016 at noon'))
        helper.recurring_schedule = {:validations=>{:day=>[1], :hour_of_day=>[9], :minute_of_hour=>[45]}, :rule_type=>"IceCube::WeeklyRule", :interval=>1, :week_start=>0}
        expect( helper.relative_next_occurrence ).to be_within(1.minute).of(Time.parse("2016-11-07 09:45:00 -0500"))
      end
    end
  end

  context 'handles fixed schedules' do
    context 'relative to a supplied date' do
      it 'can provide a time by parsing its static_schedule field' do
        expect( static_helper.next_occurrence(Chronic.parse('January 1, 2020 at 00:00')) ).to be_within(5).of(Time.parse("2020-01-01 00:01:00 -0500"))
      end
    end
    context 'relative to now' do
      it 'can provide a time by parsing its static_schedule field' do
        expect( static_helper.next_occurrence ).to be_within(5).of(Time.now + 1.minute)
      end
    end
  end
end
