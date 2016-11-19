if Rails.env.development? || Rails.env.production_local?
  puts "STI Tables being loaded into global variables."
  require_dependency Rails.root.join("app","models","channel.rb").to_s
  CHANNEL_TYPES = %w[ AnnouncementsChannel ScheduledMessagesChannel OrderedMessagesChannel
                              RandomMessagesChannel OnDemandMessagesChannel
                              IndividuallyScheduledMessagesChannel ]
  CHANNEL_TYPES.each do |c|
    require_dependency Rails.root.join("app","models","channels","#{c.underscore}.rb").to_s
  end

  require_dependency Rails.root.join("app","models","message.rb").to_s
  MESSAGE_TYPES = %w[SimpleMessage PollMessage ResponseMessage ActionMessage TagMessage]
  MESSAGE_TYPES.each do |c|
    require_dependency Rails.root.join("app","models","messages","#{c.underscore}.rb").to_s
  end

  require_dependency Rails.root.join("app","models","subscriber_activity.rb").to_s
  SUBSCRIBER_ACTIVITY_TYPES = %w[DeliveryNotice SubscriberResponse DeliveryErrorNotice]
  SUBSCRIBER_ACTIVITY_TYPES.each do |c|
    require_dependency Rails.root.join("app","models","subscriber_activities","#{c.underscore}.rb").to_s
  end

  require_dependency Rails.root.join("app","models","action.rb").to_s
  ACTION_TYPES = %w[SwitchChannelAction SendMessageAction]
  ACTION_TYPES.each do |c|
    require_dependency Rails.root.join("app","models","actions","#{c.underscore}.rb").to_s
  end
end
