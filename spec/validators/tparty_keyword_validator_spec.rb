require 'spec_helper'

describe TpartyKeywordValidator do
  subject {TpartyKeywordValidator.new({attributes:[:tparty_keyword]})}
  describe 'validate_each' do
    let(:attribute){:tparty_keyword}
    let(:record){OpenStruct.new({:errors=>{attribute=>[]}})}
    let(:value){Faker::Lorem.word}
    it 'calls messaging_manager to validate' do
      mm=double
      allow(MessagingManager).to receive(:new_instance){mm}
      expect(mm).to receive(:validate_tparty_keyword){ |value|
        expect(value).to eq(value)
      }
      subject.validate_each(record,attribute,value)
    end
    it 'returns error if messaging_manager returns error' do
      mm=double
      error = Faker::Lorem.sentence
      allow(MessagingManager).to receive(:new_instance){mm}
      allow(mm).to receive(:validate_tparty_keyword){ error } 
      subject.validate_each(record,attribute,value)
      expect(record.errors[attribute].length).to be > 0
      expect(record.errors[attribute][0]).to eq(error)
    end
    it 'does not populate error if messaging_manager returns nil' do
      mm = double
      allow(MessagingManager).to receive(:new_instance){mm}
      allow(mm).to receive(:validate_tparty_keyword){nil}
      subject.validate_each(record,attribute,value)
      expect(record.errors[attribute]).to eq([])
    end
  end
end
