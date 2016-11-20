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

    def user
      @user ||= User.find(@user_id)
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
      end
      orig['potential_channels'] = potential_channels.map(&:id)
      orig = orig.merge(subscriptions_hash)
      orig
    end

    def reject_fields
      %w(additional_attributes data deleted_at last_msg_seq_no)
    end

    def potential_channels
      @potential_channels ||= Channel.by_user(user)
    end

    def days_delta(dt)
      ((Time.now - dt) / 86400.0).to_i rescue false
    end

    def subscriptions_hash
      sh = {}
      in_channels = []
      not_in_channels = []
      @item.subscriptions.each do |subs|
        chn = subs.channel
        in_channels << chn.id
        sh["subscriber_subscription_in_channel_#{chn.id}"] = true
        sh["subscriber_subscription_channel_subscribed_at_#{chn.id}"] = subs.created_at
      end
      potential_channels.each do |pc|
        next if in_channels.include?(pc.id)
        sh["subscriber_subscription_in_channel_#{pc.id}"] = false
        sh["subscriber_subscription_channel_subscribed_at_#{pc.id}"] = false
        not_in_channels << pc.id
      end
      sh['subscriber_subscribed_channel_ids'] = in_channels
      sh['subscriber_not_in_channel_ids'] = not_in_channels
      last_subscriber_reply = @item.subscriber_responses.order(created_at: :desc).limit(1).first
      if last_subscriber_reply
        sh['subscriber_has_replies'] = true
        sh['subscriber_replied_at'] = last_subscriber_reply.created_at
        sh['subscriber_total_replies'] = @item.subscriber_responses.count
      else
        sh['subscriber_has_replies'] = false
        sh['subscriber_replied_at'] = false
        sh['subscriber_total_replies'] = 0
      end
      sh
    end

    def custom_attributes
      @item.custom_attributes
    end
  end
end
