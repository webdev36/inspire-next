require 'spec_helper'

describe RelativeSchedule do
  let(:subject){Class.new{
    extend RelativeSchedule
    def self.schedule=(val)
      @schedule=val
    end
    def self.schedule
      @schedule
    end
    }
  }
  before do
    subject.relative_schedule_type='Week'
    subject.relative_schedule_number = 10
    subject.relative_schedule_day='Sunday'
    subject.relative_schedule_hour=14
    subject.relative_schedule_minute=50      
  end
  
  describe "schedule_errors" do
    it 'does not allow type to be anything outside of minute,hour,day and week' do
      subject.relative_schedule_type='Error'
      expect(subject.schedule_errors).not_to be_nil
    end
    
    it 'validates arguments when type is minute' do
      subject.relative_schedule_type='Minute'
      subject.relative_schedule_number = -10
      expect(subject.schedule_errors).not_to be_nil
      subject.relative_schedule_number = 10
      expect(subject.schedule_errors).to eq([nil,nil])
    end

    it 'validates arguments when type is Hour' do
      subject.relative_schedule_type='Hour'
      subject.relative_schedule_number = -10
      expect(subject.schedule_errors).not_to eq([nil,nil])
      
      subject.relative_schedule_number = 10
      subject.relative_schedule_minute = -10
      expect(subject.schedule_errors).not_to eq([nil,nil])
      
      subject.relative_schedule_minute = 70
      expect(subject.schedule_errors).not_to eq([nil,nil])
    
      subject.relative_schedule_minute = 45
      subject.relative_schedule_number = 10
      expect(subject.schedule_errors).to eq([nil,nil])
    end

    it 'validates arguments when type is Day' do
      subject.relative_schedule_type='Day'

      subject.relative_schedule_number = -10
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_number = 10
      subject.relative_schedule_minute = -10
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_minute = 70
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_minute = 45
      subject.relative_schedule_hour = -5
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_hour = 24
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_hour = 18
      expect(subject.schedule_errors).to eq([nil,nil])

    end

    it 'validates arguments when type is week' do
      subject.relative_schedule_type='Week'
      
      subject.relative_schedule_number = -10
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_number = 10
      subject.relative_schedule_hour = -10
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_hour = 24
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_hour = 18
      subject.relative_schedule_minute = -10
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_minute = 70
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_minute = 45
      subject.relative_schedule_day = 'Someday'
      expect(subject.schedule_errors).not_to eq([nil,nil])

      subject.relative_schedule_day = 'Sunday'
      expect(subject.schedule_errors).to eq([nil,nil])
    end
  end
  describe "schedule_text" do
    it "constructs right schedule text" do
      subject.relative_schedule_type='Minute'
      expect(subject.schedule_text).to eq('Minute 10')
      subject.relative_schedule_type='Hour'
      expect(subject.schedule_text).to eq('Hour 10 50')
      subject.relative_schedule_type='Day'
      expect(subject.schedule_text).to eq('Day 10 14:50')
      subject.relative_schedule_type='Week'
      expect(subject.schedule_text).to eq('Week 10 Sunday 14:50')
    end
  end

  describe "get_field_from_schedule_text" do
    it "returns fields when type is minute" do
      subject.schedule = 'Minute 10'
      expect(subject.get_field_from_schedule_text(:relative_schedule_type)).to eq('Minute')
      expect(subject.get_field_from_schedule_text(:relative_schedule_number)).to eq("10")
      expect(subject.get_field_from_schedule_text(:relative_schedule_minute)).to be_nil
    end
    it "returns fields when type is hour" do
      subject.schedule = 'Hour 10 50'
      expect(subject.get_field_from_schedule_text(:relative_schedule_type)).to eq('Hour')
      expect(subject.get_field_from_schedule_text(:relative_schedule_number)).to eq("10")
      expect(subject.get_field_from_schedule_text(:relative_schedule_minute)).to eq("50")
      expect(subject.get_field_from_schedule_text(:relative_schedule_hour)).to be_nil
    end
    it "returns fields when type is day" do
      subject.schedule = 'Day 10 14:50'
      expect(subject.get_field_from_schedule_text(:relative_schedule_type)).to eq('Day')
      expect(subject.get_field_from_schedule_text(:relative_schedule_number)).to eq("10")
      expect(subject.get_field_from_schedule_text(:relative_schedule_hour)).to eq("14")
      expect(subject.get_field_from_schedule_text(:relative_schedule_minute)).to eq("50")
      expect(subject.get_field_from_schedule_text(:relative_schedule_day)).to be_nil
    end
    it "returns fields when type is week" do
      subject.schedule = 'Week 10 Sunday 14:50'
      expect(subject.get_field_from_schedule_text(:relative_schedule_type)).to eq('Week')
      expect(subject.get_field_from_schedule_text(:relative_schedule_number)).to eq("10")
      expect(subject.get_field_from_schedule_text(:relative_schedule_day)).to eq('Sunday')
      expect(subject.get_field_from_schedule_text(:relative_schedule_hour)).to eq("14")
      expect(subject.get_field_from_schedule_text(:relative_schedule_minute)).to eq("50")
    end
  end

  describe "target_time" do
    let(:from_time) {Time.new(2014,1,1,10,10)} #Wednesday
    it "returns right target time when type is minute" do
      subject.schedule = 'Minute 20'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,1,10,30))
      subject.schedule = 'Minute 55'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,1,11,5))
    end
    it "returns right target time when type is hour" do
      subject.schedule = 'Hour 2 15'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,1,11,15))
      subject.schedule = 'Hour 1 15'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,1,10,15))
    end
    it "returns right target time when type is day" do
      subject.schedule = 'Day 2 18:15'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,2,18,15))
    end         
    it "returns right target time when type is day and hour has not passed" do
      subject.schedule = 'Day 1 18:15'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,1,18,15))
      subject.schedule = 'Day 2 18:15'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,2,18,15))
    end             
    it "returns right target time when type is week" do
      subject.schedule = 'Week 2 Tuesday 18:15'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,14,18,15))
    end
    it "returns right target time when type is week and same week" do
      subject.schedule = 'Week 1 Thursday 18:15'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,2,18,15))
    end 
    it "returns right target time when type is 1 week and day has passed" do
      subject.schedule = 'Week 1 Tuesday 18:15'
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,7,18,15))
    end        
    it "returns right target time when type is week and we are scheduling on the same day and time is past" do
      subject.schedule = "Week 1 Wednesday 8:00"
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,8,8,0))
      subject.schedule = "Week 2 Wednesday 8:00"
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,15,8,0))   
      subject.schedule = "Week 1 Wednesday 10:00"
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,8,10,0))
      subject.schedule = "Week 2 Wednesday 10:00"
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,15,10,0))            
    end
    it "returns right target time when type is week and we are scheduling on the same day and time is in future" do
      subject.schedule = "Week 1 Wednesday 16:00"
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,1,16,0))
      subject.schedule = "Week 2 Wednesday 16:00"
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,8,16,0))
      subject.schedule = "Week 1 Wednesday 10:15"
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,1,10,15))
      subject.schedule = "Week 2 Wednesday 10:15"
      expect(subject.target_time(from_time)).to eq(Time.new(2014,1,8,10,15))
    end
  end

  describe "reverse_engineer_target_time" do
    let(:from_time) {Time.new(2014)} #Wednesday
    it "returns right target time when type is minute" do
      subject.schedule = 'Minute 20'
      expect(subject.reverse_engineer_target_time(from_time)).to eq(Time.new(2013,12,31,23,39))
    end
    it "returns right target time when type is hour" do
      subject.schedule = 'Hour 2 15'
      expect(subject.reverse_engineer_target_time(from_time)).to eq(Time.new(2013,12,31,21,44))
    end
    it "returns right target time when type is day" do
      subject.schedule = 'Day 2 18:15'
      expect(subject.reverse_engineer_target_time(from_time)).to eq(Time.new(2013,12,30,00,00))
    end   
    it "returns right target time when type is week" do
      subject.schedule = 'Week 2 Tuesday 18:15'
      expect(subject.reverse_engineer_target_time(from_time)).to eq(Time.new(2013,12,18,00,00))
    end
    it "returns right target time when type is week and same week" do
      subject.schedule = 'Week 1 Thursday 18:15'
      expect(subject.reverse_engineer_target_time(from_time)).to eq(Time.new(2013,12,25,00,00))
    end 
  end  

end