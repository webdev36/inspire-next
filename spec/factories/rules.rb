FactoryGirl.define do
  factory :rule do
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.sentence }
    priority 1
    selection { 'subscribers.all' }
    rule_if { 'date_is_today?(subscriber_created_at)' }
    rule_then { 'send_message_id_3355' }
  end
end
