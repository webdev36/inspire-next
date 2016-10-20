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
      @record.errors[@attribute].should == []
    end
    it 'approves valid multiple emails' do
      subject.validate_each(@record,@attribute,'abc@example.com,abc@def.com,abc@temp.com')
      @record.errors[@attribute].should == []
      subject.validate_each(@record,@attribute,'abc@example.com;abc@def.com;abc@temp.com')
      @record.errors[@attribute].should == []
      subject.validate_each(@record,@attribute,'abc@example.com  abc@def.com  abc@tempo.com')
      @record.errors[@attribute].should == []
      subject.validate_each(@record,@attribute,'abc@example.com,,abc@def.com,,abc@temp.com')
      @record.errors[@attribute].should == []      
    end  
    it 'fails invalid single email' do
      subject.validate_each(@record,@attribute,'abcexample.com')
      @record.errors[@attribute].length.should > 0
    end   
    it 'fails invalid multiple emails' do
      subject.validate_each(@record,@attribute,'abc@example.com,abcdef.com,abc@temp.com')
      @record.errors[@attribute].length.should > 0
      subject.validate_each(@record,@attribute,'abc@example.com;abc@def.com;abctemp.com')
      @record.errors[@attribute].length.should > 0
      subject.validate_each(@record,@attribute,'abcexample.com  abc@def.com  abc@tempo.com')
      @record.errors[@attribute].length.should > 0
      subject.validate_each(@record,@attribute,'abc@example.com,,abc@def.com,,abctemp.com')
      @record.errors[@attribute].length.should > 0      
    end        
  end
end