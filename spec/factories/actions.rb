# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :action do
    type "SwitchChannelAction"
    as_text {"Switch channel to #{rand 100}"}
  end

  factory :hint do
    type "Hint"
  end

  factory :switch_channel_action do
    type "SwitchChannelAction"
    to_channel {"#{rand(1000)}"}
  end

  factory :send_message_action do
    type "SendMessageAction"
    message_to_send {"#{rand(1000)}"}
  end
 end
