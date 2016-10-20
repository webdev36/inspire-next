require 'spec_helper'

describe PhoneNumberValidator do
  subject {PhoneNumberValidator.new({:attributes=>[:some_phone_number]})}
  describe 'validates' do
    before do
      @attribute = :some_phone_number
      @record = OpenStruct.new({:errors=>{:some_phone_number=>[]}})
    end    
    it 'local phone numbers' do
      subject.validate_each(@record,@attribute,'(408)232-3434')
      expect(@record.errors[:some_phone_number]).to eq([])      
      subject.validate_each(@record,@attribute,'4082323434')
      expect(@record.errors[:some_phone_number]).to eq([])            
      subject.validate_each(@record,@attribute,'408 232 3434')
      expect(@record.errors[:some_phone_number]).to eq([])            
    end
    it 'international phone numbers' do
      subject.validate_each(@record,@attribute,'+14082323434')
      expect(@record.errors[:some_phone_number]).to eq([])      
      subject.validate_each(@record,@attribute,'+1 408 232 3434')
      expect(@record.errors[:some_phone_number]).to eq([])      
      subject.validate_each(@record,@attribute,'+1 (408) 232-3434')
      expect(@record.errors[:some_phone_number]).to eq([])      
    end
    it 'flags short numbers as invalid' do
      subject.validate_each(@record,@attribute,'2343434')
      expect(@record.errors[:some_phone_number].length).to be > 0
    end
    it 'flags long numbers as invalid' do
      subject.validate_each(@record,@attribute,'140823434343434')
      expect(@record.errors[:some_phone_number].length).to be > 0
    end    
  end
end