# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :message_option do
    message_id 1
    key "MyString"
    value "MyString"
  end
end
