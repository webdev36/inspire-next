require 'spec_helper'

RSpec.describe Rule, type: :model do
  context 'setup' do
    it 'has a working factory' do
      expect { create :rule }.to_not raise_error
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
      travel_to_string_time("December 30, 2016 12:00")
      rule = @user.rules.new
      rule.name = "Change channel on quit date."
      rule.selection = 'subscribers_all'
      rule.rule_if = '(-2 < subscriber_days_delta_quit_date) && (subscriber_days_delta_quit_date <= -1)'
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
      Timecop.return
      rule = @user.rules.new
      rule.name = "Switch channel on Quit Date"
      rule.selection = 'subscribers_all'
      rule.rule_if = 'subscriber_created_at > now'
      resp = rule.rule_if_objects
      expect(resp.length == 0).to be_truthy
      travel_to_string_time("December 30, 2016 12:00")
      rule = @user.rules.new
      rule.selection = 'subscribers_all'
      rule.rule_if = 'subscriber_days_delta_quit_date <= -1'
      resp = rule.rule_if_objects
      expect(resp.length == 1).to be_truthy
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
