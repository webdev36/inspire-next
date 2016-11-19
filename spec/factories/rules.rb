FactoryGirl.define do
  factory :rule do
    name "Created more than a week ago"
    description 'If the user has been in the system 7 days, and does not have a quit date, send them a reminder text'
    priority 1
    selection { 'subscribers.all' }
    rule_if { 'subscriber_added_days_ago == 7 and subscriber_quit_date.nil?' }
    rule_then { 'send_message channel.243.message.335' }
  end
end
