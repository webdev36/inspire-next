require 'spec_helper'

describe OneWordValidator do
  subject {OneWordValidator.new({:attributes=>[:some_one_word_field]})}
  describe 'validates' do
    before do
      @attribute = :some_one_word_field
      @record = OpenStruct.new({:errors=>{:some_one_word_field=>[]}})
    end    
    it 'single words' do
      subject.validate_each(@record,@attribute,'oneword')
      @record.errors[:some_one_word_field].should == []      
      subject.validate_each(@record,@attribute,'one_word_still')
      @record.errors[:some_one_word_field].should == []            
      subject.validate_each(@record,@attribute,'again-one-word')
      @record.errors[:some_one_word_field].should == []            
    end
    it 'flags blanks as invalid' do
      subject.validate_each(@record,@attribute,'')
      @record.errors[:some_one_word_field].length.should > 0
    end
    it 'flags multiple words as invalid' do
      subject.validate_each(@record,@attribute,'two words')
      @record.errors[:some_one_word_field].length.should > 0
    end
  end
end