require 'ice_cube'

class MessageFactory
  attr_accessor :params, :supplied_message, :channel, :opts

  def initialize(_p, chn = nil, msg = nil, _o = {})
    @params = HashWithIndifferentAccess.new(_p)
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
    msg = construct_recurring_if_present(msg)
    msg
  end

  # private

    def construct_recurring_if_present(msg)
      if recurring_schedule?
        if icecube_rule
          msg.recurring_schedule = icecube_rule.to_hash
          msg.next_send_time = 1.minute.ago
        elsif !recurring_schedule.blank? # no changes
          msg.recurring_schedule = recurring_schedule
        end
      end
      msg
    end

    def recurring_schedule?
      (params['one_time_or_recurring'].present? &&
        params['one_time_or_recurring'] == 'recurring') ||
          (!recurring_schedule.blank? && is_update?)
    end

    def recurring_schedule
      @recurring_schedule ||= begin
        raw = params['message'].try(:[], 'recurring_schedule')
        raw = nil if ['custom'].include?(raw)
        raw
      end
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
        mparams['recurring_schedule'] = {} if mparams['recurring_schedule'] == 'custom' # universally make sure it passed, added later in process
        mparams['recurring_schedule'] = JSON.parse(mparams['recurring_schedule']) if mparams['recurring_schedule'].is_a?(String)
      end
      mparams
    end

    def message_recurring_params
      raw_txt = params['message'].try(:[], 'recurring_schedule')
      if raw_txt && !['custom'].include?(raw_txt)
        JSON.parse(raw_txt)
      else
        {}
      end
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
      msg.action.data['ensure_not_in_channels'] = Array(params['ensure_not_in_channels']).map(&:to_i)
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

    def recurrence_hash
      {
        'rule_type': icecube_type,
        'interval': icecube_interval,

      }
    end

    # {"validations"=>{"day"=>[1], "hour_of_day"=>[9], "minute_of_hour"=>[45]}, "rule_type"=>"IceCube::WeeklyRule", "interval"=>1, "week_start"=>0}
    def recurrence_params
      params.select { |key, value| recurrence_params_fields.include?(key) }
    end

    def icecube_rule
      case recurrence_params['rs_frequency']
      when 'Daily'
        IceCube::Rule.daily(recurrence_params['rs_daily_interval'].to_i)
                     .hour_of_day(recurrence_params['rs_daily_hour_of_day'].to_i)
                     .minute_of_hour(recurrence_params['rs_daily_minute_of_hour'].to_i)
      when 'Weekly'
        IceCube::Rule.weekly(recurrence_params['rs_weekly_interval'].to_i)
                     .hour_of_day(recurrence_params['rs_weekly_hour_of_day'].to_i)
                     .minute_of_hour(recurrence_params['rs_weekly_minute_of_hour'].to_i)
      when 'Monthly'
        IceCube::Rule.monthly(recurrence_params['rs_monthly_interval'])
      when 'Yearly'
        IceCube::Rule.yearly(recurrence_params['rs_yearly_interval'])
      else
        nil
      end
    end

    def recurrence_params_fields
      %w( rs_frequency rs_daily_interval rs_daily_hour_of_day
          rs_daily_minute_of_hour rs_weekly_interval rs_weekly_hour_of_day
          rs_weekly_minute_of_hour rs_monthly_interval rs_monthly_hour_of_day
          rs_monthly_minute_of_hour rs_yearly_interval )
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

    def is_create?
      action == 'create'
    end

    def is_update?
      action == 'update'
    end

    def action
      params['action']
    end
end
