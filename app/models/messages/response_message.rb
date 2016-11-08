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

class ResponseMessage < Message

  def self.user_accessible_message_type?
    true
  end

  def type_abbr
    'Response'
  end

  def requires_user_response?
    true
  end

  def has_action_on_user_response?
    true
  end

  def process_subscriber_response(sr)
    flag_executed = false
    flag_executed = true if response_actions.length == 0
    response_actions.each do |ra|
      if sr.content_text =~ /#{ra.response_text}/im
        if ra.action
          ra.action.execute({:subscribers=>[sr.subscriber],:from_channel=>channel})
          handle_subscriber_response_success(sr, 'matched text triggered execution', 'response action')
          flag_exectued = true
          break
        else
          handle_subscriber_response_error(sr, 'matched text but no action supplied', 'response action')
        end
      end
    end
    if flag_executed == false
      handle_subscriber_response_error(sr, 'nsubscriber response not matched', 'response action')
    end
    true
  end
end

