class SubscriberActivityReportSender
  include Sidekiq::Worker

  def perform(frequency)
    case frequency
    when :hourly
      self.class.send_hourly_report
    when :daily
      self.class.send_daily_report
    end
  end

  def self.send_hourly_report
    StatsD.increment("subscriber_activity_report_sender.hourly")
    email_ch_group = group_for_report(:hourly)
    email_ch_group.each do |email,targets|
      SubscriberActivityReportMailer.hourly_subscriber_activity_report(email,targets)
    end
  end

  def self.send_daily_report
    StatsD.increment("subscriber_activity_report_sender.hourly")
    email_ch_group = group_for_report(:daily)
    email_ch_group.each do |email,targets|
      SubscriberActivityReportMailer.daily_subscriber_activity_report(email,targets)
    end
  end

  def self.group_for_report(frequency)
    if frequency==:hourly
      start_time = 1.hour.ago
      realtime = true
    else
      start_time = 1.day.ago
      realtime=[nil,false]
    end
    email_ch_hash = {}
    channel_ids = SubscriberActivity.where("created_at > ?",start_time).
      uniq.pluck(:channel_id).compact
    channels = Channel.where("id in (?)",channel_ids).
      where('moderator_emails is not null').
      where("moderator_emails <> ''").
      where(real_time_update:realtime)
    channels.each do |ch|
      emails = ch.moderator_emails.split(/[\s+,;]/).compact
      emails.each do |email|
        email.strip!
        if email_ch_hash[email]
          email_ch_hash[email] << ch
        else
          email_ch_hash[email] = [ch]
        end
      end
    end
    channel_group_ids = SubscriberActivity.where("created_at > ?",start_time).
      uniq.pluck(:channel_group_id).compact
    channel_groups = ChannelGroup.where("id in (?)",channel_group_ids).
      where('moderator_emails is not null').
      where("moderator_emails <> ''").
      where(real_time_update:realtime)
    channel_groups.each do |ch_group|
      emails = ch_group.moderator_emails.split(/\s+,;/)
      emails.each do |email|
        email.strip!
        if email_ch_hash[email]
          email_ch_hash[email] << ch_group
        else
          email_ch_hash[email] = [ch_group]
        end
      end
    end
    email_ch_hash
  end

  def self.group_daily_report_by_id

  end
end
