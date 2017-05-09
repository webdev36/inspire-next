require 'csv'

class ExportChannel
  attr_accessor :channel_id

  def initialize(channel_id)
    @channel_id = channel_id
  end

  def channel
    @channel ||= Channel.find(channel_id)
  end

  def messages
    @messages ||= channel.messages
  end

  def to_csv
    CSV.generate do |csv|
      csv << ["***MESSAGES***"]
      csv << messages.first.attributes.keys
      messages.each do |message|
        csv << message.attributes.values
      end
      csv << ["***MESSAGESEND***"]
      if message_actions.length > 0
        csv << ["***MESSAGESACTIONS***"]
        csv << message_actions.first.attributes.keys
        message_actions.each do |ma|
          csv << ma.attributes.values
        end
        csv << ["***MESSAGESACTIONSEND***"]
      end
      if message_options.length > 0
        csv << ["***MESSAGEOPTIONS***"]
        csv << message_options.first.attributes.keys
        message_options.each do |mo|
          csv << mo.attributes.values
        end
        csv << ["***MESSAGEOPTIONSEND***"]
      end
      if response_actions.length > 0
        csv << ["***RESPONSEACTIONS***"]
        csv << response_actions.first.attributes.keys
        response_actions.each do |ra|
          csv << ra.attributes.values
        end
        csv << ["***RESPONSEACTIONSEND***"]
      end
      if response_actions_actions.length > 0
        csv << ["***RESPONSEACTIONSACTIONS***"]
        csv << response_actions_actions.first.attributes.keys
        response_actions_actions.each do |ra|
          csv << ra.attributes.values
        end
        csv << ["***RESPONSEACTIONSACTIONSEND***"]
      end
    end
  end

  def message_ids
    @message_ids ||= channel.messages.pluck(:id)
  end

  def message_actions
    @message_actions ||= Action.where(actionable_type: 'Message')
                               .where(actionable_id: Array(message_ids)).to_a
  end

  def message_options
    @message_options ||= MessageOption.where(message_id: message_ids).to_a
  end

  def response_actions
    @response_actions ||= ResponseAction.where(message_id: message_ids).to_a
  end

  def response_actions_ids
    @response_actions_ids ||= response_actions.map(&:id)
  end

  def response_actions_actions
    @response_actions ||= Action.where(actionable_type: 'ResponseAction')
                               .where(actionable_id: response_actions_ids).to_a
  end

end
