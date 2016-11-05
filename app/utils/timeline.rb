class Timeline
  attr_accessor :subscriber
  # aggregates up the timeline of the subscriber

  def self.timeline(subscriber)
    helper = new(subscriber)
    helper.timeline
  end

  def initialize(subscriber)
    @subscriber = subscriber
    @added = {}
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

  def timeline
    @timeline ||= begin
      tl = []
      map_by_type = {}
      subscriber_responses.each { |sr| add_to_timeline(sr) }
      subscriber_activities.each { |sa| add_to_timeline(sa) }
      timeline_array.sort { |a, b| b.created_at <=> a.created_at }
    end
  end

  def subscriber_activities
    SubscriberActivity.of_subscriber(@subscriber)
  end

  def subscriber_responses
    subscriber.subscriber_responses
  end

end
