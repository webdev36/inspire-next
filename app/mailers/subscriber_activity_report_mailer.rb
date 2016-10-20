class SubscriberActivityReportMailer < ActionMailer::Base
  default from: "inspire@omalab.com"

  def hourly_subscriber_activity_report(email,targets)
    @targets = targets
    timestr = Time.now.strftime("%F %R")
    mail(to:email,subject:"Hourly subscriber activity for #{timestr}")
  end

  def daily_subscriber_activity_report(email,targets)
    @targets = targets
    timestr = Time.now.strftime("%F")
    mail(to:email,subject:"Daily subscriber activity for #{timestr}")    
  end
end
