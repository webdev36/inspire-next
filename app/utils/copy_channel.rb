# The copyvchannel copies the messages adn actions from one channel to
# antoher, usually empty one.
# all the messages and response actions for the channel

class CopyChannel
  attr_accessor :params, :channel_group, :message_map

  def self.copy!(old_id, new_id)
    helper = new(old_id, new_id)
    helper.copy_messages
  end

  def initialize(old_id, new_id)
    @old_channel_id = old_id
    @new_channel_id = new_id
    @message_map = {}
  end

  def old_channel
    @old_channel ||= Channel.find(@old_channel_id)
  end

  def new_channel
    @new_channel ||= Channel.find(@new_channel_id)
  end

  def copy_messages
    old_channel.messages.each do |old_message|
      new_message = create_copy_message(old_message)
      clone_response_actions(old_message, new_message)
      clone_message_options(old_message, new_message)
    end
  end

  def attributes_to_delete
    %w(id created_at updated_at seq_no)
  end

  def create_copy_message(old_message, user_id = nil)
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
      if new_message.save
        message_map[old_message.id] = new_message.id
      else
        binding.pry
      end
    end
    new_message
  end

  def clone_response_actions(old_msg, new_msg)
    old_msg.response_actions.each do |old_response_action|
      create_copy_response_action new_msg, old_response_action
    end
  end

  def clone_message_options(old_msg, new_msg)
    old_msg.message_options.each do |option|
      new_option = new_msg.message_options.new
      new_option.key = option.key
      new_option.value = option.value
      new_option.message_id = new_msg.id
      if new_option.save
        next
      else
        raise RuntimeError.new "Cannot create a message option"
      end
    end
  end

  def create_copy_response_action(new_msg, old_response_action)
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

  def create_copy_message_options(new_msg, old_response_action)
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
