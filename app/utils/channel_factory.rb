require 'ice_cube'

class ChannelFactory
  attr_accessor :params, :supplied_channel, :channel_group, :opts, :user

  def initialize(_p, chn = nil, user = nil, chn_group = nil, _o = {})
    @params = HashWithIndifferentAccess.new(_p)
    @user = user
    @supplied_channel = chn
    @channel_group = chn_group
    @opts = _o
  end

  def initial_channel
    @initial_channel ||= begin
      if new_channel?
        chn = Channel.new channel_params
      else
        chn = supplied_channel
        chn.update_attributes channel_params if channel_params
      end
      chn.user_id = user.try(:id)
      chn.schedule = {} # will set recurring schedule if there is one.
      chn
    end
  end

  def channel
    chn = initial_channel
    chn = construct_recurring_if_present(chn)
    chn
  end

  # private
    def construct_recurring_if_present(chn)
      chn.schedule = nil
      if recurring_schedule?
        chn.schedule = icecube_rule.to_hash if icecube_rule
      end
      chn
    end

    def recurring_schedule?
      Array(channel_params&.keys).include?('schedule') &&
        !channel_params.try(:[], 'schedule').try(:blank?)
    end

    def schedule
      @schedule ||= JSON.parse(params['schedule']) if params['schedule']
    end

    def new_channel?
      supplied_channel.nil?
    end

    def channel_params
      mparams = params['channel']
      mparams
    end

    def channel_type
      params.try(:[], 'channel').try(:[], 'type')
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

end
