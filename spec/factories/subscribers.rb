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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscriber do
    name {Faker::Name.name}
    phone_number {Faker::PhoneNumber.us_phone_number}#{"1-(#{rand(100..999)}) #{rand(100..999)} #{rand(1000..9999)}"}
    remarks {Faker::Lorem.sentence}
    user
  end
end
