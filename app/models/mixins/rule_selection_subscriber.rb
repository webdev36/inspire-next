module Mixins
  module RuleSelectionSubscriber
    extend ActiveSupport::Concern

    # takes the raw results and queries for any successful completions of
    # this rule in the lat 24 hours.  if so, filters them out of the
    # list, reutrning the list of subscribers
    def subscriber_selection_objects
      if recent_successful_subscriber_ids.length > 0
        raw_subscriber_selection_objects
          .where("subscribers.id NOT IN (?)", recent_successful_subscriber_ids)
      else
        raw_subscriber_selection_objects
      end
    end

    # queries the RuleActivity to find subscribers where the rules have already
    # been run. Adds them to an id list for skipping.
    def recent_successful_subscriber_ids
      @recent_successful_subscriber_ids ||= begin
        rss = RuleActivity.where(:rule_id => self.id)
                          .where(:ruleable_type => 'Subscriber')
                          .where(:success => true)
                          .where(:created_at => 24.hours.ago..Time.now)
        if raw_subscriber_selection_object_ids
          rss = rss.where(:ruleable_type => 'Subscriber')
                   .where(:ruleable_id => raw_subscriber_selection_object_ids)
        end
        rss.pluck(:ruleable_id).uniq
      end
    end

    # used in the recent_successful_ids to limit the list to the raw
    # selected list. Is this more efficient? not really sure.
    def raw_subscriber_selection_object_ids
      @raw_subscriber_selection_object_ids ||= raw_subscriber_selection_objects.map(&:id)
    end

    # does the query for subscribers based on the tags that are supplied
    # by the rule
    def raw_subscriber_selection_objects
      @raw_subscriber_selection_objects ||= begin
        if selection == 'subscribers_all'
          user.subscribers
        elsif selection.include?('subscriber_id_')
          sub_id = selection.gsub('subscriber_id_', '')
          user.subscribers.where(id: sub_id)
        elsif selection.include?('subscriber_in_channel_')
          chn_id = selection.gsub('subscriber_in_channel_', '')
          user.channels.find(chn_id).subscribers
        else
          []
        end
      end
    end
  end
end
