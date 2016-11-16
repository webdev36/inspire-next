require 'csv'

class ImportChannel
  attr_accessor :channel_id, :file, :opts, :error_rows

  def initialize(channel_id, file, opts = {})
    @channel_id = channel_id
    @file = file
    @opts = opts
    @error_rows = []
    @success_count = 0
  end

  def id_map
    @id_map ||= {
      messages: {},
      message_actions: {},
      message_options: {},
      response_actions: {},
      response_actions_actions: {}
    }
  end

  def import
    import_messages
    import_message_actions
    import_message_options
    import_reponse_actions
    import_reponse_actions_actions
  end

  def csv_string
    @csv_string ||= File.read(file.path).scrub
  end

  def messages_string
    string_between_markers(csv_string, '***MESSAGES***', '***MESSAGESEND***')
  end

  def message_objects
    @message_objects ||= begin
      create_objects(messages_string) do |rh|
        item = Message.where(:id => rh['id']).try(:first)
        item = channel.messages.new if item.nil?
        if opts[:override_channel]
          item.channel_id = channel.id
        end
        if opts[:new_import]
          item.id = nil
        end
        item
      end
    end
  end

  def import_messages
    import_objects(Message, message_objects)
  end

  def messages_actions_string
    string_between_markers(csv_string, '***MESSAGESACTIONS***', '***MESSAGESACTIONSEND***')
  end

  def message_actions_objects
    @message_actions_objects ||= begin
      create_objects(messages_actions_string) do |rh|
        item = Action.where(:actionable_type => 'Message', :actionable_id => rh['id']).try(:first)
        item = Action.new if item.nil?
        item
      end
    end
  end

  def import_message_actions
    import_objects(Action, message_actions_objects)
  end

  def messages_options_string
    string_between_markers(csv_string, '***MESSAGEOPTIONS***', '***MESSAGEOPTIONSEND***')
  end

  def message_options_objects
    @message_options_objects ||= begin
      create_objects(messages_options_string) do |rh|
        item = MessageOption.where(:id => rh['id']).try(:first)
        item = MessageOption.new if item.nil?
        item
      end
    end
  end

  def import_message_options
    import_objects(MessageOption, message_options_objects)
  end

  def response_actions_string
    string_between_markers(csv_string, '***RESPONSEACTIONS***', '***RESPONSEACTIONSEND***')
  end

  def response_actions_objects
    @response_actions_objects ||= begin
      create_objects(response_actions_string) do |rh|
        item = ResponseAction.where(:id => rh['id']).try(:first)
        item = ResponseAction.new if item.nil?
        item
      end
    end
  end

  def import_reponse_actions
    import_objects(ResponseAction, response_actions_objects)
  end

  def response_actions_actions_string
    string_between_markers(csv_string, '***RESPONSEACTIONSACTIONS***', '***RESPONSEACTIONSACTIONSEND***')
  end

  def response_actions_actions_objects
    @response_actions_actions_objects ||= begin
      create_objects(response_actions_actions_string) do |rh|
        item = Action.where(:actionable_type => 'ResponseAction', :actionable_id => rh['id']).try(:first)
        item = Action.new if item.nil?
        item
      end
    end
  end

  def import_reponse_actions_actions
    import_objects(Action, response_actions_actions_objects)
  end

  def channel
    @channel ||= Channel.find(channel_id)
  end

  # strip off teh rest of the row of the header, if it exists
  def string_between_markers(str, marker1, marker2)
    raw = str[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
    raw.to_s.gsub(/^,+\r\n/, '')
  end

  def convert_string_to_iterator(str)
    CSV.parse(str, headers: true)
  end

  def has_content?(str)
    !str.nil? && !str.blank? && str.include?(',')
  end

  def create_objects(str)
    return [] if !has_content?(str)
    convert_string_to_iterator(str).map do |row|
      if row.to_hash.keys.length > 2
        rh = row.to_hash
        item = yield rh
        rh.keys.each do |key|
          next if key.nil? or key.blank?
          rh[key] = {} if rh[key] == '{}'
          item.send("#{key}=", rh[key])
        end
        item
      else
        nil
      end
    end.delete_if { |item| item.blank? || item.nil? }
  end

  def import_objects(klass, objects)
    return true if objects.length == 0
    to_import = []
    objects.each do |item|
      if item.id
        if item.save
          @success_count += 1
        else
          @error_rows << item
        end
      else
        to_import << item
      end
    end
    if to_import.length > 0
      resp = klass.import to_import, validate: false
    end
  end
end
