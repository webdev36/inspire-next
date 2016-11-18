class MessageFactory
  def initialize(strong_params, params, message: nil, channel: nil)
    @strong_params = strong_params.to_h
    @params = params
    @current_message = message
    @channel = channel

    if @current_message.nil? && message_type != "ActionMessage"
      @strong_params.delete "action_attributes"
    end

    @strong_params['recurring_schedule'] = nil if @strong_params['recurring_schedule'] == 'null'

    if message_type == "ActionMessage"
      @data = { resume_from_last_state: @strong_params["action_attributes"]["resume_from_last_state"] }
      @strong_params["action_attributes"].delete "resume_from_last_state"
    end
  end

  def message
    @message ||= begin
      message = if @current_message.nil?
        @channel.messages.new @strong_params
      else
        @strong_params['recurring_schedule'] = JSON.parse(@strong_params['recurring_schedule']) if @strong_params['recurring_schedule']
        binding.pry
        @strong_params.keys.each do |key|
          @current_message[key] = @strong_params[key]
        end
        @current_message.action = nil unless message_type == "ActionMessage"
        @current_message
      end
      binding.pry
      message = construct_switch_channel_message(message) if switch_channel_action_message?
      message = construct_send_message_message(message)   if send_message_action_message?

      if @params[:one_time_or_recurring].present?
        case @params[:one_time_or_recurring]
        when "one_time"
          message.recurring_schedule = nil
        when "recurring"
          message.next_send_time = 1.minute.ago
        end
      end

      message
    end
  end

  private

    def channel
      @channel ||= Channel.find(@params['channel_id'])
    end

    def not_in_channel_group?
      channel.channel_group_id.blank?
    end

    def in_channel_group?
      !not_in_channel_group?
    end

    def more_than_one_channel?
      channels_for_switching.length > 1
    end

    def channels_for_switching
      @channels_for_switching ||= begin
        cfw = []
        Array(@params[:to_channel_in_group]  ).each { |ch| cfw << ch }
        Array(@params[:to_channel_out_group] ).each { |ch| cfw << ch }
        cfw
      end
    end

    def construct_switch_channel_message(msg)
      msg.action.data[:to_channel_in_group]    = Array(@params[:to_channel_in_group])
      msg.action.data[:to_channel_out_group]   = Array(@params[:to_channel_out_group])
      msg.action.data[:resume_from_last_state] = @data[:resume_from_last_state]
      if more_than_one_channel? && in_channel_group?
        msg.action.to_channel = @params[:to_channel_in_group].sort.first
      elsif more_than_one_channel?
        msg.action.to_channel = @params[:to_channel_out_group].sort.first
      else
        msg.action.to_channel = channels_for_switching.first
      end
      msg.action.construct_action
      msg
    end

    def construct_send_message_message(msg)
      msg
    end

    def message_type
      @strong_params["type"]
    end

    def message_action
      @strong_params.try(:[], "action_attributes").try(:[], "type")
    end

    def switch_channel_action_message?
      message_type == "ActionMessage" && message_action == "SwitchChannelAction"
    end

    def send_message_action_message?
      message_type == "ActionMessage" && message_action == "SendMessageAction"
    end
end
