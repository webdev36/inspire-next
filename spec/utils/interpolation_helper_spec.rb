require 'spec_helper'

describe InterpolationHelper do
  context 'works' do
    let(:user)       { create :user }
    let(:subscriber) { subx = create :subscriber; subx.additional_attributes= "quit_date=11/23/2016;first_name=Tom;last_name=Jerry;"; subx.save; subx }
    let(:helper)     { InterpolationHelper.new(subscriber, user.id) }

    # gut check that its working
    it 'interpolates subscriber fields' do
      expect(helper.to_hash.keys.length > 0).to be_truthy
    end

    it 'skips rejected fields' do
      expect(helper.to_hash.keys.include?('subscriber_additional_attributes')).to be_falsey
    end

    # takes the attributes that are in the additional addtributeds and
    # puts them into the interpolation hash so we can query and use them in
    # rules
    it 'adds additional attributes as fields' do
      expect(helper.to_hash['subscriber_quit_date'].blank?).to be_falsey
    end

    # takes date and time fields and claculates from NOW how many days the
    # delta is for them
    it 'adds days_delta attributes for date/time fields' do
      expect(helper.to_hash['subscriber_days_delta_quit_date'].blank?).to be_falsey
    end
  end

  context 'subscriber' do
    it 'subscriptions are in interpolation hash' do
      setup_user_and_individually_scheduled_messages_relative_schedule
      @subscriber = create :subscriber, user: @user
      @channel.subscribers << @subscriber
      helper = InterpolationHelper.new(@subscriber, @user.id)
      expect(helper.to_hash['subscriber_subscribed_channels'].length > 0).to be_truthy
    end
  end
end
