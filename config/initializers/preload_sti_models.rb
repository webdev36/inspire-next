if Rails.env.development?
  require_dependency Rails.root.join("app","models","channel.rb").to_s
  %w[AnnouncementsChannel ScheduledMessagesChannel OrderedMessagesChannel
    RandomMessagesChannel OnDemandMessagesChannel
    IndividuallyScheduledMessagesChannel].each do |c|
    require_dependency Rails.root.join("app","models","channels","#{c.underscore}.rb").to_s
  end
  require_dependency Rails.root.join("app","models","message.rb").to_s
  %w[SimpleMessage PollMessage ResponseMessage ActionMessage TagMessage].each do |c|
    require_dependency Rails.root.join("app","models","messages","#{c.underscore}.rb").to_s
  end
  require_dependency Rails.root.join("app","models","subscriber_activity.rb").to_s
  %w[DeliveryNotice SubscriberResponse].each do |c|
    require_dependency Rails.root.join("app","models","subscriber_activities","#{c.underscore}.rb").to_s
  end
  require_dependency Rails.root.join("app","models","action.rb").to_s
  %w[SwitchChannelAction SendMessageAction].each do |c|
    require_dependency Rails.root.join("app","models","actions","#{c.underscore}.rb").to_s
  end

  Rails.logger.info "*****#{Channel.child_classes.map(&:to_s)}"
  Rails.logger.info "*****#{Message.child_classes.map(&:to_s)}"
  Rails.logger.info "*****#{SubscriberActivity.child_classes.map(&:to_s)}"
  Rails.logger.info "*****#{Action.child_classes.map(&:to_s)}"
end
