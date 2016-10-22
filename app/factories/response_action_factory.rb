class ResponseActionFactory
  def initialize(strong_params, params, response_action: nil, message: nil)
    @strong_params = strong_params.to_h
    @params = params
    @current_response_action = response_action
    @message = message
    @data = { resume_from_last_state: @strong_params["action_attributes"]["resume_from_last_state"] }
    @strong_params["action_attributes"].delete "resume_from_last_state"
  end

  def response_action
    @response_action ||= begin

      response_action = if @current_response_action.nil?
        @message.response_actions.new @strong_params
      else
        @current_response_action.assign_attributes @strong_params
        @current_response_action
      end
      response_action = construct_switch_channel_response(response_action) if switch_channel_action?
      response_action = construct_send_message_response(response_action)   if send_message_action?
      response_action
    end
  end

  private

    def construct_switch_channel_response(ra)
      ra.action.data[:to_channel_in_group]    = Array(@params[:to_channel_in_group])
      ra.action.data[:to_channel_out_group]   = Array(@params[:to_channel_out_group])
      ra.action.data[:resume_from_last_state] = @data[:resume_from_last_state]

      # logic. the default switcher will swich in channel if in a channel group
      if more_than_one_channel? && in_channel_group?
        ra.action.to_channel = @params[:to_channel_in_group].sort.first
      elsif more_than_one_channel?
        ra.action.to_channel = @params[:to_channel_out_group].sort.first
      else
        ra.action.to_channel = channels_for_switching.first
      end
      ra.action.construct_action
      ra
    end

    def construct_send_message_response(ra)
      ra.action.as_text = "Send message #{message_to_send}"
      ra.action.construct_action
      ra
    end

    def message_to_send
      @strong_params["action_attributes"]['message_to_send']
    end

    def message
      @message ||= Message.find(@params['message_id'])
    end

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

    def action_type
      @strong_params.try(:[], "action_attributes").try(:[], "type")
    end

    def switch_channel_action?
      action_type == "SwitchChannelAction"
    end

    def send_message_action?
      action_type == "SendMessageAction"
    end
end
