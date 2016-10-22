class Timeline
  attr_accessor :subscriber
  # aggregates up the timeline of the subscriber

  def self.timeline(subscriber)
    helper = new(subscriber)
    helper.timeline
  end

  def initialize(subscriber)
    @subscriber = subscriber
  end

  def timeline
    @timeline ||= begin
      tl = []
      subscriber_responses.each { |sr| tl << sr }
      subscriber_activities.each { |sa| tl << sa }
      tl.sort {|a, b| b.created_at <=> a.created_at }
    end
  end

  def subscriber_activities
    SubscriberActivity.of_subscriber(@subscriber)
  end

  def subscriber_responses
    subscriber.subscriber_responses
  end

end
