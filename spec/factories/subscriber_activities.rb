# == Schema Information
#
# Table name: subscriber_activities
#
#  id               :integer          not null, primary key
#  subscriber_id    :integer
#  channel_id       :integer
#  message_id       :integer
#  type             :string(255)
#  origin           :string(255)
#  title            :text
#  caption          :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  channel_group_id :integer
#  processed        :boolean
#  deleted_at       :datetime
#

FactoryGirl.define do
  factory :subscriber_activity do
    type "SubscriberResponse"
    origin  {Faker::PhoneNumber.us_phone_number}
    title   {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}

    subscriber nil
    channel nil
    message nil
  end

  factory :delivery_notice do
    type "DeliveryNotice"
    subscriber
    message
    channel nil
  end

  factory :action_notice do
    type "ActionNotice"
    subscriber
    caption "Moved subscriber from <a href=\"/channels/1\">laudantium in</a> to <a href=\"/channels/2\">omnis asperiores</a>"
  end

  factory :subscriber_response do
    transient do
      tparty_keyword ""
      message_content ""
    end
    type "SubscriberResponse"
    origin {Faker::PhoneNumber.us_phone_number}
    caption {"#{tparty_keyword} #{message_content}"}
    subscriber
    channel nil
    message nil
  end

end
