# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#

class SwitchChannelAction < Action
  include Rails.application.routes.url_helpers
  include ActionView::Helpers

  before_validation :construct_action
  validate :check_action_text

  def type_abbr
    'Switch Subscriber'
  end

  def description
    'Switch a subscriber to a new channel'
  end

  def check_action_text
    if !(as_text=~/^Switch channel to \d+$/)
      errors.add :as_text, "action format is invalid"
    end
  end

  def construct_action
    self.as_text = "Switch channel to #{to_channel}"
  end

  def execute(opts={})
    if opts[:subscribers].nil? ||
      opts[:subscribers].empty? || (opts[:from_channel].nil? && opts[:channel].nil?)
      return false
    end
    subscribers = opts[:subscribers]
    fc = opts[:from_channel] || opts[:channel]
    tc = Channel.find_by_id(to_channel) rescue nil
    if !tc
      return false
    end
    kosher=true
    subscribers.each do |subs|
      if !fc.subscribers.include?(subs)
        # determine if this is an "on demand" command. If so, ignore the source channel.
        if ["OnDemandMessagesChannel"].include?(fc.type)
          siblings = fc.channel_group.channels.includes(:subscribers)
          siblings.each do |check_channel|
            if check_channel.subscribers.detect{|subscriber| subscriber.phone_number == subs.phone_number}
              # set the found sibling channel to teh channel that we need ot remove teh sub from
              fc = check_channel
              break
            end
          end
        else
          kosher = false
        end
      end
    end
    if !kosher
      return false
    end
    subscribers.each do |subscriber|
      fc.subscribers.delete(subscriber) rescue nil
      tc.subscribers << subscriber if  !tc.subscribers.include?(subscriber)
      notice_text = "Moved subscriber from "+
            content_tag("a",fc.name,href:channel_path(fc))+
            " to "+
            content_tag("a",tc.name,href:channel_path(tc))
      ActionNotice.create(caption:notice_text,subscriber:subscriber)
    end
    return true
  rescue
    return false
  end
end
