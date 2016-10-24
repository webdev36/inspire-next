require 'spec_helper'

describe EmailsValidator do
  subject {EmailsValidator.new({:attributes=>[:moderator_emails]})}
  describe 'validates' do
    before do
      @attribute = :moderator_emails
      @record = OpenStruct.new({:errors=>{:moderator_emails=>[]}})
    end    
    it 'approves valid single email' do
      subject.validate_each(@record,@attribute,'abc@example.com')
      expect(@record.errors[@attribute]).to eq([])
    end
    it 'approves valid multiple emails' do
      subject.validate_each(@record,@attribute,'abc@example.com,abc@def.com,abc@temp.com')
      expect(@record.errors[@attribute]).to eq([])
      subject.validate_each(@record,@attribute,'abc@example.com;abc@def.com;abc@temp.com')
      expect(@record.errors[@attribute]).to eq([])
      subject.validate_each(@record,@attribute,'abc@example.com  abc@def.com  abc@tempo.com')
      expect(@record.errors[@attribute]).to eq([])
      subject.validate_each(@record,@attribute,'abc@example.com,,abc@def.com,,abc@temp.com')
      expect(@record.errors[@attribute]).to eq([])      
    end  
    it 'fails invalid single email' do
      subject.validate_each(@record,@attribute,'abcexample.com')
      expect(@record.errors[@attribute].length).to be > 0
    end   
    it 'fails invalid multiple emails' do
      subject.validate_each(@record,@attribute,'abc@example.com,abcdef.com,abc@temp.com')
      expect(@record.errors[@attribute].length).to be > 0
      subject.validate_each(@record,@attribute,'abc@example.com;abc@def.com;abctemp.com')
      expect(@record.errors[@attribute].length).to be > 0
      subject.validate_each(@record,@attribute,'abcexample.com  abc@def.com  abc@tempo.com')
      expect(@record.errors[@attribute].length).to be > 0
      subject.validate_each(@record,@attribute,'abc@example.com,,abc@def.com,,abctemp.com')
      expect(@record.errors[@attribute].length).to be > 0      
    end        
  end
end