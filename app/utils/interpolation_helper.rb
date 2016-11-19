class InterpolationHelper
  attr_accessor :item, :user_id

  # the interpolation helper calss method to get an interpolation  hash back
  # for the user
  def self.to_hash(item, user_id = nil)
    new(item, user_id).to_hash
  end

  def initialize(item, user_id = nil)
    @item = item
    @user_id = user_id
  end

  def user
    @user ||= User.where(:id => user_id).try(:first)
  end

  def valid?
    fields.length > 0
  end

  def fields
    Array(to_hash.try(:keys))
  end

  def to_hash
    case item.class.name
    when 'User' then UserPresenter.new(item, user_id).to_hash
    when 'Subscriber' then SubscriberPresenter.new(item, user_id).to_hash
    end
  end

  module LiquidModelPresenter
    extend ActiveSupport::Concern
    def initialize(item, user_id = nil)
      @item = item
      @user_id = user_id
    end

    def system_url
      {
        'User' => "/users/edit.#{user_id}",
        'Subscriber' => '/subscribers/#{@item.id}'
      }[@item.class.name]
    end

    def kind
      {
        'User' => "user",
        'Subscriber' => 'subscriber'
      }[@item.class.name]
    end

    def original_fields
      to_hash.keys
    end

    def to_hash
      @to_hash ||= begin
        hsh = @item.attributes.stringify_keys.delete_if { |k,v| reject_fields.include?(k) }
        resp = Hash[hsh.map {|k, v| ["#{kind}_#{k}", v] }]
        unless @project_id.blank?
          Array(project_specific_fields).each do |psf|
            resp[psf] = @item.attributes[psf][project_id]
          end
          resp["#{kind}_system_url"] = system_url(@project_id)
        end
        resp['now'] = Time.now
        resp
      end
    end

    def reject_fields
      []
    end

    def user_specific_fields
      []
    end
  end

  class UserPresenter
    include LiquidModelPresenter

    def to_hash
      orig = super
      orig
    end
  end

  class SubscriberPresenter
    include LiquidModelPresenter

    def to_hash
      orig = super
      custom_attributes.keys.each do |custom_attribute_key|
        orig["subscriber_#{custom_attribute_key}"] = custom_attributes[custom_attribute_key]
        if [DateTime, Time, ActiveSupport::TimeWithZone].include?(custom_attributes[custom_attribute_key].class)
          orig["subscriber_days_delta_#{custom_attribute_key}"] = days_delta(custom_attributes[custom_attribute_key])
          orig.delete("subscxriber__days_delta_#{custom_attribute_key}") if orig["subscriber_days_delta_#{custom_attribute_key}"] == false
        end
      end
      orig["subscriber_days_delta_created_at"] = days_delta(@item.created_at)
      orig = orig.merge(subscriptions_hash)
      orig
    end

    def reject_fields
      %w(additional_attributes)
    end

    def days_delta(dt)
      ((Time.now - dt) / 86400.0).to_i rescue false
    end

    def subscriptions_hash
      sh = {}
      in_channels = []
      @item.subscriptions.each do |subs|
        chn = subs.channel
        in_channels << chn.id
        sh["subscriber_subscription_channel_#{chn.id}"] = true
        sh["subscriber_subscription_channel_#{chn.id}_at"] = subs.created_at
        sh["subscriber_subscription_channel_days_delta_#{chn.id}"] = days_delta(subs.created_at)
      end
      sh['subscriber_subscribed_channels'] = in_channels
      sh
    end

    def custom_attributes
      @item.custom_attributes
    end
  end
end
