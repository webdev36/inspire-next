# == Schema Information
#
# Table name: channel_groups
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  description        :text
#  user_id            :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  tparty_keyword     :string(255)
#  keyword            :string(255)
#  default_channel_id :integer
#  moderator_emails   :text
#  real_time_update   :boolean
#  deleted_at         :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :channel_group do
    name {Faker::Lorem.words.join(' ')}
    description {Faker::Lorem.sentence}
    tparty_keyword {ENV['TPARTY_PRIMARY_KEYWORD'] || "INSPIRE"}
    user
  end
end
