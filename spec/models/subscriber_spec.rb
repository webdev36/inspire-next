# == Schema Information
#
# Table name: subscribers
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  phone_number    :string(255)
#  remarks         :text
#  last_msg_seq_no :integer
#  user_id         :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  email           :string(255)
#  deleted_at      :datetime
#

require 'spec_helper'

describe Subscriber do
  it "has a valid factory" do
    expect(build(:subscriber)).to be_valid
  end
  it "requires phone_number" do
    expect(build(:subscriber,phone_number:'')).to_not be_valid
  end
  
  it "requires phone_number to be unique for the same user" do
    subscriber = create(:subscriber)
    expect(build(:subscriber,user:subscriber.user,phone_number:subscriber.phone_number)).to_not be_valid
  end
  
  it "does not require phone_number to be unique across users" do
    subscriber = create(:subscriber)
    another_user = create(:user)
    expect(build(:subscriber,user:another_user,phone_number:subscriber.phone_number)).to be_valid
  end

  it "requires phone number to be 10 or 11 digits" do
    expect(build(:subscriber,phone_number:'2343434')).to_not be_valid
    expect(build(:subscriber,phone_number:'2343434454545')).to_not be_valid
  end

  it "requires valid email if present" do
    expect(build(:subscriber,email:'')).to be_valid
    expect(build(:subscriber,email:'abc')).to_not be_valid
    expect(build(:subscriber,email:'abc@def.com')).to be_valid
  end
  
  it "converts phone number to international format upon save" do
    subscriber = create(:subscriber,phone_number:'408-234-3434')
    subscriber.phone_number.should == '+14082343434'
    subscriber = create(:subscriber,phone_number:'(408) 234 3434')
    subscriber.phone_number.should == '+14082343434'
    subscriber = create(:subscriber,phone_number:'14082343434')
    subscriber.phone_number.should == '+14082343434'
    subscriber = create(:subscriber,phone_number:'+14082343434')
    subscriber.phone_number.should == '+14082343434'
  end

  it "find_by_phone_number works for all formats of the same number" do
    subscriber = create(:subscriber, phone_number:'(408) 234 3434')
    Subscriber.find_by_phone_number('+14082343434').should == subscriber
    Subscriber.find_by_phone_number('408 234 3434').should == subscriber
    Subscriber.find_by_phone_number('(408)234-3434').should == subscriber
    Subscriber.find_by_phone_number('+1(408)234 3434').should == subscriber
  end

  describe 'format_phone_number' do
    it 'works for phone numbers in international format' do
      Subscriber.format_phone_number('+14082322324').should == '+14082322324'
      Subscriber.format_phone_number('+1(408)232-2324').should == '+14082322324'
      Subscriber.format_phone_number('+1(408) 232 2324').should == '+14082322324'
    end
    it 'works for phone numbers in local format' do
      Subscriber.format_phone_number('4082322324').should == '+14082322324'
      Subscriber.format_phone_number('14082322324').should == '+14082322324'
      Subscriber.format_phone_number('(408)232-2324').should == '+14082322324'
      Subscriber.format_phone_number('(408) 232 2324').should == '+14082322324'
    end
    it 'returns nil for incomplete or longer phone numbers' do
      Subscriber.format_phone_number('2322324').should be_nil
      Subscriber.format_phone_number('(408) 232 2324 6754').should be_nil
    end
  end  

  describe "#" do
    let(:user) {create(:user)}
    let(:channel) {create(:channel,user:user)}
    let(:phone_number) {Faker::PhoneNumber.us_phone_number}
    subject {create(:subscriber,user:user,phone_number:phone_number)}
    before {channel.subscribers << subject}
    it "lists the responses sent by this subscriber" do
      expect {
        create(:subscriber_response,origin:phone_number,caption:"#{channel.tparty_keyword} #{Faker::Lorem.sentence}")
        }.to change {subject.subscriber_responses.count}.by 1
    end 
  end
      
end
