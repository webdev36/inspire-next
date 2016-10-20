# == Schema Information
#
# Table name: channels
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  user_id           :integer
#  type              :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  keyword           :string(255)
#  tparty_keyword    :string(255)
#  next_send_time    :datetime
#  schedule          :text
#  channel_group_id  :integer
#  one_word          :string(255)
#  suffix            :string(255)
#  moderator_emails  :text
#  real_time_update  :boolean
#  deleted_at        :datetime
#  relative_schedule :boolean
#  send_only_once    :boolean          default(FALSE)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :channel do
    name {Faker::Lorem.words(2).join(' ')}
    description {Faker::Lorem.sentence}
    tparty_keyword {ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"}
    type="AnnouncementsChannel"
    user 
  end
  
  factory :announcements_channel do
    name {Faker::Lorem.words(2).join(' ')}
    description {Faker::Lorem.sentence}
    tparty_keyword {ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"}
    type="AnnouncementsChannel"
    user 
  end  

  factory :random_messages_channel do
    name {Faker::Lorem.words(2).join(' ')}
    description {Faker::Lorem.sentence}
    tparty_keyword {ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"}
    type="RandomMessagesChannel"
    user 
  end    

  factory :ordered_messages_channel do
    name {Faker::Lorem.words(2).join(' ')}
    description {Faker::Lorem.sentence}
    tparty_keyword {ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"}
    type="OrderedMessagesChannel"
    user 
  end   

  factory :on_demand_messages_channel do
    name {Faker::Lorem.words(2).join(' ')}
    description {Faker::Lorem.sentence}
    tparty_keyword {ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"}
    type="OnDemandMessagesChannel"
    user 
  end   

  factory :scheduled_messages_channel do
    name {Faker::Lorem.words(2).join(' ')}
    description {Faker::Lorem.sentence}
    tparty_keyword {ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"}
    type="ScheduledMessageChannel"
    user 
  end 

  factory :individually_scheduled_messages_channel do
    name {Faker::Lorem.words(2).join(' ')}
    description {Faker::Lorem.sentence}
    tparty_keyword {ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"}
    type="IndividuallyScheduledMessagesChannel"
    user 
  end     

  factory :secondary_messages_channel do
    name '_system_smc'
    tparty_keyword '_system_smc'
    description {Faker::Lorem.sentence}
    type="SecondaryMessagesChannel"
    user nil
  end        

   

end
