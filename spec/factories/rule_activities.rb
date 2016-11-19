FactoryGirl.define do
  factory :rule_activity do
    rule_id 1
    subscriber_id 1
    success false
    message "MyText"
    data "MyText"
  end
end
