require 'will_paginate/array'

class SubscriberAvailableChannels
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  def user_id
    params[:user_id]
  end

  def subscriber_id
    params[:id]
  end

  def page
    params[:available_channels_page] || 1
  end

  def per_page
    params[:available_channels_per_page] || 10
  end

  def subscriber
    @subscriber ||= Subscriber.find(subscriber_id)
  end

  def user
    @user ||= User.find(user_id)
  end

  def subscribed_channel_ids
    @subscribed_channel_ids ||= subscriptions.map{ |subscription| subscription.channel_id }
  end

  def subscriptions
    @subscriptions ||= subscriber.subscriptions
  end

  def channels
    available_channels.paginate(:page => page, :per_page => per_page)
  end

  def available_channels
    @available_channels ||= begin
      ac = []
      subscriptions.each { |subscription| ac << subscription.channel }
      user.channel_groups.each do |channel_group|
        channel_group.channels.each do |channel|
          ac << channel unless ac.include?(channel)
        end
      end
      user.channels.each do |channel|
        ac << channel unless ac.include?(channel)
      end
      ac
    end
  end
end
