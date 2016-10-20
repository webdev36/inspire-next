# == Schema Information
#
# Table name: messages
#
#  id                           :integer          not null, primary key
#  title                        :text
#  caption                      :text
#  type                         :string(255)
#  channel_id                   :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  content_file_name            :string(255)
#  content_content_type         :string(255)
#  content_file_size            :integer
#  content_updated_at           :datetime
#  seq_no                       :integer
#  next_send_time               :datetime
#  primary                      :boolean
#  reminder_message_text        :text
#  reminder_delay               :integer
#  repeat_reminder_message_text :text
#  repeat_reminder_delay        :integer
#  number_of_repeat_reminders   :integer
#  options                      :text
#  deleted_at                   :datetime
#  schedule                     :text
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :message do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    type "SimpleMessage"
    channel
  end

  factory :simple_message do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    type "SimpleMessage"
    channel
  end

  factory :tag_message do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    type "TagMessage"
    channel
  end

  factory :poll_message do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    type "PollMessage"
    channel
  end

  factory :action_message do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    type "ActionMessage"
    channel
  end

  factory :response_message do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    type "ResponseMessage"
    channel
  end

  factory :text_message, class:'SimpleMessage' do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    type "SimpleMessage"
    channel
  end

  #The real stub using files for the paperclip attachment takes
  #execution time of a few seconds. Hence just mimicking
  #content {File.new(Rails.root + 'spec/factories/rails.png')}
  factory :image_message_pseudo, class:'Message' do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    content_file_name {"#{Faker::Lorem.word}.png"}
    content_content_type 'image/png'
    content_file_size {rand(10000)}
    content_updated_at {Time.now}
    type "SimpleMessage"
    channel
  end

  #The real stub using files for the paperclip attachment takes
  #execution time of a few seconds. Hence just mimicking
  #content {File.new(Rails.root + 'spec/factories/sample.mp4')}
  factory :video_message_pseudo, class: 'Message' do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    content_file_name {"#{Faker::Lorem.word}.mp4"}
    content_content_type "video/mp4"
    content_file_size {rand(10000000)}
    content_updated_at {Time.now}
    type "SimpleMessage"
    channel
  end

  #The real stub using files for the paperclip attachment takes
  #execution time of a few seconds. Hence just mimicking
  #content {File.new(Rails.root + 'spec/factories/sample.mp3')}
  factory :audio_message_pseudo, class: 'Message' do
    title {Faker::Lorem.sentence}
    caption {Faker::Lorem.sentence}
    content_file_name {"#{Faker::Lorem.word}.mp3"}
    content_content_type "audio/mpeg"
    content_file_size {rand(1000000)}
    content_updated_at {Time.now}
    type "SimpleMessage"
    channel
  end

end
