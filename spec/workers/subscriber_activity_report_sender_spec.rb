describe SubscriberActivityReportSender do
  it "send_hourly_report calls mailer's corresponding method with the email and list of channels" do
    Timecop.freeze(2014,1,27)
    user = create(:user)
    ch1 = create(:channel,user:user,keyword:'sample1',real_time_update:true,
      moderator_emails:'abc@example.com,def@example.com,ghi@example.com')
    ch2 = create(:channel,user:user,keyword:'sample2',moderator_emails:'def@example.com')
    ch_group = create(:channel_group,user:user,keyword:'sample3',
      moderator_emails:'ghi@example.com',real_time_update:true)
    sa0 = create(:subscriber_response,
      caption:"#{ch1.tparty_keyword} #{ch1.keyword} temp")
    Timecop.freeze(2014,1,27)
    sa1 = create(:subscriber_response,
      caption:"#{ch1.tparty_keyword} #{ch1.keyword} temp")
    sa2 = create(:subscriber_response,
      caption:"#{ch2.tparty_keyword} #{ch2.keyword} temp")   
    sa3 = create(:subscriber_response,
      caption:"#{ch_group.tparty_keyword} #{ch_group.keyword} temp")          
    Timecop.freeze(2014,1,27,0,55)
    SubscriberActivityReportMailer.should_receive(:hourly_subscriber_activity_report).exactly(3).times do |email,targets|
      case email
      when 'abc@example.com'
        targets.should =~ [Channel.find(ch1)]
      when 'def@example.com'
        targets.should =~ [Channel.find(ch1)]
      when 'ghi@example.com'
        targets.should =~ [Channel.find(ch1),ChannelGroup.find(ch_group)]
      else
        fail "unexpected email value #{email}"
      end
    end
    SubscriberActivityReportSender.send_hourly_report
    Timecop.freeze(2014,1,27,12,55)
    SubscriberActivityReportMailer.should_receive(:daily_subscriber_activity_report).exactly(1).times do |email,targets|
      case email
      when 'def@example.com'
        targets.should =~ [Channel.find(ch2)]
      else
        fail "unexpected email value #{email}"
      end
    end
    SubscriberActivityReportSender.send_daily_report
    Timecop.return 
  end

  it "send_daily_report calls mailer's corresponding method with the email and list of channels" do
  end

  describe "#" do
    let(:subject){SubscriberActivityReportSender.new}
    describe "perform" do
      it "of hourly report calls send_hourly_report method" do
        SubscriberActivityReportSender.should_receive(:send_hourly_report){}
        subject.perform(:hourly)
      end
      it "of weekly report calls send_weekly_report method" do
        SubscriberActivityReportSender.should_receive(:send_daily_report){}
        subject.perform(:daily)
      end
    end
  end
end