# The CloneChannel class copies a channel to a new channel, copying
# all the messages and response actions for the channel

class CloneChannel
  attr_accessor :params, :channel_group, :message_map

  def self.clone!(params, channel_group = nil)
    helper = new(params, channel_group)
    helper.new_channel
    helper.clone_messages
  end

  def initialize(params, channel_group = nil)
    @params = params
    @channel_group = channel_group
    @message_map = {}
  end

  def clone_messages
    channel_to_copy.messages.each do |old_message|
      new_message = create_clone_message(old_message)
      clone_response_actions(old_message, new_message)
    end
  end

  def new_channel_name
    @new_channel_name ||= params.try(:[], "request").try(:[], "name")
  end

  def channel_id_to_copy
    @channel_id_to_copy ||= params.try(:[], "request").try(:[], "choice")
  end

  def new_channel_keyword
    @new_channel_keyword ||= params.try(:[], "request").try(:[], "keyword")
  end

  def channel_to_copy
    @channel_to_copy ||= Channel.find(channel_id_to_copy)
  end

  def channel_to_copy_hash
    @channel_to_copy_hash ||= begin
      hash_copy = channel_to_copy.attributes
      attributes_to_delete.each { |atr| hash_copy.delete(atr) }
      hash_copy
    end
  end

  def new_channel
    @new_channel ||= begin
      new_channel = Channel.new
      new_channel.attributes = channel_to_copy_hash
      new_channel.user_id = channel_to_copy.user_id
      new_channel.channel_group_id = channel_group.id if channel_group
      new_channel.name = new_channel_name
      new_channel.keyword = new_channel_keyword
      new_channel.created_at = Time.current
      new_channel.updated_at = Time.current
      new_channel.save
      new_channel
    end
  end

  def attributes_to_delete
    %w(id created_at updated_at)
  end

  def create_clone_message(old_message)
    if message_map_contains_id?(old_message.id)
      new_message = Message.find(message_map[old_message.id])
    else
      new_message = Message.new
      hash_copy = old_message.attributes
      attributes_to_delete.each { |atr| hash_copy.delete(atr) }
      new_message.attributes = hash_copy
      new_message.channel_id = new_channel.id
      new_message.created_at = Time.current
      new_message.updated_at = Time.current
      new_message.save
      message_map[old_message.id] = new_message.id
    end
    new_message
  end

  def clone_response_actions(old_msg, new_msg)
    old_msg.response_actions.each do |old_response_action|
      create_clone_response_action new_msg, old_response_action
    end
  end

  def create_clone_response_action(new_msg, old_response_action)
    response_action = ResponseAction.new
    hash_copy = old_response_action.attributes
    attributes_to_delete.each { |atr| hash_copy.delete(atr) }
    response_action.attributes = hash_copy
    response_action.message_id = new_msg.id
    response_action.created_at = Time.current
    response_action.updated_at = Time.current
    response_action.save
    old_action = old_response_action.action
    if old_action
      new_action = Action.new
      hash_copy = old_action.attributes
      attributes_to_delete.each { |atr| hash_copy.delete(atr) }
      new_action.attributes = hash_copy
      new_action.actionable_id = response_action.id
      new_action.actionable_type = "ResponseAction"
      new_action.save
    end
    response_action
  end

  def message_map_contains_id?(id)
    message_map.keys.include?(id)
  end
end
