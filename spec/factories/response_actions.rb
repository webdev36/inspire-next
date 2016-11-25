FactoryGirl.define do
  factory :response_action do
    response_text {Faker::Lorem.sentence}
    action
    message
  end
end
