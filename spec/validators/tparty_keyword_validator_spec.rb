require 'spec_helper'

describe TpartyKeywordValidator do
  subject {TpartyKeywordValidator.new({attributes:[:tparty_keyword]})}
  describe 'validate_each' do
    let(:attribute){:tparty_keyword}
    let(:record){OpenStruct.new({:errors=>{attribute=>[]}})}
    let(:value){Faker::Lorem.word}
    it 'calls messaging_manager to validate' do
      mm=double
      MessagingManager.stub(:new_instance){mm}
      mm.should_receive(:validate_tparty_keyword){ |value|
        value.should == value
      }
      subject.validate_each(record,attribute,value)
    end
    it 'returns error if messaging_manager returns error' do
      mm=double
      error = Faker::Lorem.sentence
      MessagingManager.stub(:new_instance){mm}
      mm.stub(:validate_tparty_keyword){ error } 
      subject.validate_each(record,attribute,value)
      record.errors[attribute].length.should > 0
      record.errors[attribute][0].should == error
    end
    it 'does not populate error if messaging_manager returns nil' do
      mm = double
      MessagingManager.stub(:new_instance){mm}
      mm.stub(:validate_tparty_keyword){nil}
      subject.validate_each(record,attribute,value)
      record.errors[attribute].should == []
    end
  end
end
