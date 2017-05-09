require 'spec_helper'

RSpec.describe Rule, type: :model do
  context 'setup' do
    it 'has a working factory' do
      expect { create :rule }.to_not raise_error
    end
  end

  context 'cron' do
    it 'only runs active rules on the cron' do
      setup_user_and_system
      rule1 = create :rule, user: @user, active: true
      rule2 = create :rule, user: @user, active: false
      expect(Rule.active.due.count == 1).to be_truthy
    end
  end

  context 'domain specific language' do
    it 'date_is_today?' do
      rule_if ='date_is_today?(subscriber_quit_date)'
      setup_for_dsl_test
      expect_to_eval_false(rule_if)
      travel_to_string_time("January 1, 2017 12:00")
      @rule = Rule.find(@rule.id)
      expect_to_eval_true(rule_if)
    end
    it 'date_is_tomorrow?' do
      rule_if ='date_is_tomorrow?(subscriber_quit_date)'
      setup_for_dsl_test
      expect_to_eval_true(rule_if)
      travel_to_string_time("January 1, 2017 12:00")
      @rule = Rule.find(@rule.id)
      expect_to_eval_false(rule_if)
    end
    it 'date_is_yesterday?' do
      rule_if ='date_is_yesterday?(subscriber_quit_date)'
      setup_for_dsl_test
      expect_to_eval_false(rule_if)
      travel_to_string_time("January 2, 2017 12:00")
      @rule = Rule.find(@rule.id)
      expect_to_eval_true(rule_if)
    end
    it 'date_is_x_days_away?' do
      rule_if ='date_is_x_days_away?(subscriber_quit_date, 2)'
      setup_for_dsl_test
      travel_to_string_time('December 30, 2016 12:00')
      expect_to_eval_true(rule_if)
      travel_to_string_time("January 2, 2017 12:00")
      @rule = Rule.find(@rule.id)
      expect_to_eval_false(rule_if)
    end
    it 'subscriber_is_in_channel?' do
      rule_if = "*"
      setup_for_dsl_test
      rule_if = "subscriber_is_in_channel?(subscriber_subscribed_channel_ids, #{@second_channel.id})"
      @rule.rule_if = rule_if
      @rule.save
      expect_to_eval_false(rule_if)
      @second_channel.subscribers << @subscriber
      @subscriber.reload
      @rule = Rule.find(@rule.id)
      expect_to_eval_true(rule_if)
    end
    it 'subscriber_is_not_in_channel?' do
      rule_if = "*"
      setup_for_dsl_test
      rule_if = "subscriber_is_not_in_channel?(subscriber_subscribed_channel_ids, #{@second_channel.id})"
      @rule.rule_if = rule_if
      @rule.save
      expect_to_eval_true(rule_if)
      @second_channel.subscribers << @subscriber
      @subscriber.reload
      @rule = Rule.find(@rule.id)
      expect_to_eval_false(rule_if)
    end
    def setup_for_dsl_test
      setup_user_and_system
      travel_to_string_time("November 1, 2016 11:00")
      @subscriber.additional_attributes = "quit_date=1/1/2017;first_name=Jom;"
      @subscriber.save
      @second_channel = create :channel, user: @user
      @rule = @user.rules.new
      @rule.name = "Test Rule"
      @rule.selection = 'subscribers_all'
      @rule.rule_if = '*'
      @rule.rule_then = "remove_subscriber_from_channel_#{@channel.id}"
      expect(@rule.save).to be_truthy
      travel_to_string_time("December 31, 2016 12:00")
    end
    def expect_to_eval_true(rule_if)
      @rule.rule_if = rule_if
      expect(@rule.rule_if_true_for_object(@subscriber)).to be_truthy
    end
    def expect_to_eval_false(rule_if)
      @rule.rule_if = rule_if
      expect(@rule.rule_if_true_for_object(@subscriber)).to be_falsey
    end
  end
  context 'skipping already processed' do
    it 'does not add to rule when already processed' do
      setup_user_and_system
      sub2 = create :subscriber, user: @user
      sub3 = create :subscriber, user: @user
      @channel.subscribers << sub2
      @channel.subscribers << sub3
      @second_channel = create :channel, user: @user
      travel_to_string_time("November 1, 2016 11:00")
      sub4 = create(:subscriber, user: @user)
      sub4.additional_attributes = "quit_date=1/1/2017;first_name=Jom;"
      sub4.save
      @channel.subscribers << sub4
      travel_to_string_time("December 31, 2016 12:00")
      rule = @user.rules.new
      rule.name = "Change channel on quit date."
      rule.selection = 'subscribers_all'
      rule.rule_if = 'date_is_tomorrow?(subscriber_quit_date)'
      rule.rule_then = "remove_subscriber_from_channel_#{@channel.id} add_subscriber_to_channel_#{@second_channel.id}"
      rule.save
      rule.process
      rid = rule.id
      expect(@second_channel.subscribers.count == 1).to be_truthy
      expect(@channel.subscribers.count == 2).to be_truthy
      # reload the rule
      ra_count = RuleActivity.count
      travel_to_same_day_at(13,0)
      rule = Rule.find(rid)
      rule.process
      expect(rule.recent_successful_subscriber_ids.include?(sub4.id)).to be_truthy
      expect(rule.rule_if_objects.length == 0).to be_truthy
      expect(@second_channel.subscribers.count == 1).to be_truthy
      expect(@channel.subscribers.count == 2).to be_truthy
    end
  end

  context 'rule_then' do
    it 'can change channels when if criteria met' do
      setup_user_and_system
      @second_channel = create :channel, user: @user
      travel_to_string_time("November 1, 2016 11:00")
      subscriber = create(:subscriber, user: @user)
      subscriber.additional_attributes = "quit_date=1/1/2017;first_name=Jom;"
      subscriber.save
      travel_to_string_time("December 31, 2016 12:00")
      rule = @user.rules.new
      rule.name = "Change channel on quit date."
      rule.selection = 'subscribers_all'
      rule.rule_if = 'date_is_tomorrow?(subscriber_quit_date)'
      rule.rule_then = "add_subscriber_to_channel_#{@second_channel.id} remove_subscriber_from_channel_#{@channel.id}"
      rule.save
      resp = rule.rule_then_objects
      expect(@second_channel.subscribers.count == 1).to be_truthy
      expect(@channel.subscribers.count == 0).to be_truthy
    end
  end

  context 'rule_if' do
    it 'interpolates if statement for each users data' do
      setup_user_and_system
      travel_to_string_time("November 1, 2016 11:00")
      subscriber = create(:subscriber, user: @user)
      subscriber.additional_attributes = "quit_date=1/1/2017;first_name=Jom;"
      subscriber.save
      travel_to_string_time("December 30, 2016 12:00")
      rule = @user.rules.new
      rule.name = "Switch channel on Quit Date"
      rule.selection = 'subscribers_all'
      rule.rule_if = 'subscriber_created_at > now'
      resp = rule.rule_if_objects
      expect(resp.length == 0).to be_truthy
      rule = @user.rules.new
      rule.selection = 'subscribers_all'
      rule.rule_if = 'date_is_x_days_away?(subscriber_quit_date, 2)'
      resp = rule.rule_if_objects
      expect(resp.length == 1).to be_truthy
    end

    it 'passes all through if the if statement is *' do
      setup_user_and_system
      travel_to_string_time("November 1, 2016 11:00")
      Timecop.return
      rule = @user.rules.new
      rule.name = "Switch channel on Quit Date"
      rule.selection = 'subscribers_all'
      rule.rule_if = '*'
      resp = rule.rule_if_objects
      expect(resp.length == Subscriber.count).to be_truthy
    end

    context 'subscribers' do
      it 'uses interpolation hash' do
        setup_user_and_system
        subs_wo_sub = []
        2.times do
          subs_wo_sub << create(:subscriber, user: @user)
        end
        subs_w_sub = []
        2.times do
          swx = create(:subscriber, user: @user)
          @channel.subscribers << swx
          subs_w_sub << swx
        end
        rule = @user.rules.new
        rule.selection = 'subscribers_all'
        rule.rule_if = "subscriber_days_delta_created_at > -1"
        resp = rule.selection_objects.call
        expect(resp.length == 5).to be_truthy
      end
    end
  end

  context 'selection' do
    context 'subscribers' do
      it 'can select all the users subscribers' do
        setup_user_and_system
        subsx = []
        3.times do
          subsx << create(:subscriber, user: @user)
        end
        rule = @user.rules.new
        rule.selection = 'subscribers_all'
        expect(rule.selection_class == 'subscriber').to be_truthy
        resp = rule.selection_objects.call
        expect(resp.length == 4).to be_truthy
      end

      it 'can select a single subscriber' do
        setup_user_and_system
        subsx = []
        3.times do
          subsx << create(:subscriber, user: @user)
        end
        selected_subscriber = subsx.sample
        rule = @user.rules.new
        rule.selection = "subscriber_id_#{selected_subscriber.id}"
        expect(rule.selection_class == 'subscriber').to be_truthy
        resp = rule.selection_objects.call
        expect(resp.first.id == selected_subscriber.id).to be_truthy
      end

      it 'can select all subscribers in a channel' do
        setup_user_and_system
        subs_wo_sub = []
        2.times do
          subs_wo_sub << create(:subscriber, user: @user)
        end
        subs_w_sub = []
        2.times do
          swx = create(:subscriber, user: @user)
          @channel.subscribers << swx
          subs_w_sub << swx
        end
        rule = @user.rules.new
        rule.selection = "subscriber_in_channel_#{@channel.id}"
        expect(rule.selection_class == 'subscriber').to be_truthy
        resp = rule.selection_objects.call
        expect(resp.length == 2).to be_truthy
      end
    end
  end
end
