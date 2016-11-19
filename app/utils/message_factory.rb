class MessageFactory
  attr_accessor :params, :supplied_message, :channel, :opts

  def initialize(_p, chn = nil, msg = nil, _o = {})
    @params = _p
    @supplied_message = msg
    @channel = chn
    @opts = _o
  end

  def initial_message
    @initial_message ||= begin
      if new_message?
        msg = @channel.messages.new message_params
      else
        msg = supplied_message
        msg.update_attributes message_params if message_params
      end
      msg.action = nil unless message_type == 'ActionMessage'
      msg
    end
  end

  def message
    msg = initial_message
    msg = construct_switch_channel_message(msg) if switch_channel_action_message?
    msg = construct_send_message_message(msg)   if send_message_action_message?
    msg = construct_one_time_or_recurring(msg)
    msg
  end

  private

    def construct_one_time_or_recurring(msg)
      if params[:one_time_or_recurring].present?
        case params[:one_time_or_recurring]
        when "one_time"
          msg.recurring_schedule = nil
        when "recurring"
          msg.next_send_time = 1.minute.ago
        end
      end
      msg
    end

    def recurring_schedule?
      recurring_schedule.is_a?(Hash)
    end

    def recurring_schedule
      @recurring_schedule ||= JSON.parse(params['recurring_schedule']) if params['recurring_schedule']
    end

    def new_message?
      supplied_message.nil?
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

    def message_params
      mparams = params['message']
      if mparams && mparams.keys.length > 0
        mparams.delete('action_attributes') unless mparams['type'] == 'ActionMessage'
        mparams.delete('message_options_attributes') unless mparams['type'] == 'TagMessage'
      end
      mparams
    end

    def message_action_params
      params.try(:[], 'message').try(:[], 'action_attributes')
    end

    def message_options_params
      params.try(:[], 'message').try(:[], 'message_options_attributes')
    end

    def channels_for_switching
      @channels_for_switching ||= begin
        cfw = []
        Array(params['to_channel_in_group']).each { |ch| cfw << ch.to_i }
        Array(params['to_channel_out_group']).each { |ch| cfw << ch.to_i }
        cfw
      end
    end

    def construct_switch_channel_message(msg)
      msg.action.data['to_channel_in_group']    = Array(params['to_channel_in_group']).map(&:to_i)
      msg.action.data['to_channel_out_group']   = Array(params['to_channel_out_group']).map(&:to_i)
      # msg.action.data[:resume_from_last_state] = data[:resume_from_last_state]
      if more_than_one_channel? && in_channel_group?
        msg.action.to_channel = params['to_channel_in_group'].sort.first
      elsif more_than_one_channel?
        msg.action.to_channel = params['to_channel_out_group'].sort.first
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
      params.try(:[], 'message').try(:[], 'type')
    end

    def message_action
      params.try(:[], 'message').try(:[], "action_attributes").try(:[], "type")
    end

    def switch_channel_action_message?
      message_type == "ActionMessage" && message_action == "SwitchChannelAction"
    end

    def send_message_action_message?
      message_type == "ActionMessage" && message_action == "SendMessageAction"
    end
end
