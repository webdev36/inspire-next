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

class DeliveryNotice < SubscriberActivity
  attr_accessible :subscriber, :message, :channel, :channel_group

  after_initialize do |dn|
    if dn.new_record?
      begin
        dn.processed = true
      rescue ActiveModel::MissingAttributeError
      end
    end
  end

  scope :recently_sent, -> { where(created_at: 2.hours.ago..Time.now) }

  def self.recently_sent_count
    recently_sent.count
  end

  def self.of_primary_messages
    includes(:message).where("messages.primary=true").references(:messages)
  end

  def self.of_primary_messages_that_require_response
    includes(:message).where("messages.primary=true AND messages.requires_response=true").references(:messages)
  end

end
