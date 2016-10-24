require 'securerandom'
class TpartyScheduledMessageSender
  include Sidekiq::Worker

  def perform
    self.class.send_scheduled_messages
  end

  def self.send_scheduled_messages
    StatsD.increment("tparty.send_scheduled_messages")
    channels = channels_pending_send
    return if !channels
    channels.each do |channel|
      StatsD.increment("channel.#{channel.id}.send_scheduled_messages")
      channel.send_scheduled_messages
    end
  end

  def self.channels_pending_send
    Channel.pending_send.active
  end
end
