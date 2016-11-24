require 'will_paginate/array'

class Timeline
  attr_accessor :params
  # aggregates up the timeline of the subscriber
  def self.timeline(params)
    helper = new(params)
    helper.timeline
  end

  def self.timeline_export(params)
    helper = new(params)
    helper.timeline_export
  end

  def initialize(params)
    @params = params
    @added = {}
  end

  def subscriber_id
    @subscriber_id ||= params[:id]
  end

  def subscriber
    @subscriber ||= Subscriber.find(subscriber_id)
  end

  def page
    @page ||= params[:timeline_page] || 1
  end

  def per_page
    @per_page ||= params[:timeline_per_page] || 10
  end

  def timeline
    timeline_map.paginate(page: page, per_page: per_page)
  end

  def timeline_array
    @timeline_array ||= []
  end

  def add_to_timeline(item)
    @added[item.class.name] = [] if @added[item.class.name].nil?
    unless @added[item.class.name].include?(item.id)
      timeline_array << item
      @added[item.class.name] << item.id
    end
  end

  def timeline_export
    @timeline_export ||= begin
      timeline_map
      te = []
      timeline_array.each do |tmi|
        te << tmi.attributes.to_hash
      end
      te
    end
  end

  def timeline_map
    @timeline_map ||= begin
      tl = []
      map_by_type = {}
      subscriber_responses.each { |sr| add_to_timeline(sr) }
      subscriber_activities.each { |sa| add_to_timeline(sa) }
      timeline_array.sort { |a, b| b.created_at <=> a.created_at }
    end
  end

  def subscriber_activities
    SubscriberActivity.of_subscriber(subscriber)
  end

  def subscriber_responses
    subscriber.subscriber_responses
  end

end
