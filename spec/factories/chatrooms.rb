FactoryGirl.define do
  factory :chatroom do
    name { Faker::Hipster.words(2).join(".") }
    user
  end
end
