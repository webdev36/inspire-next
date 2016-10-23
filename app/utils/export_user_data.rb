# this class exports a user's project details, putting them into a large
# single JSON file in the tmp folder

class ExportUserData

  def initialize(user)
    @user = user
  end

  def run
    Files.json_write_to_tmp_path("#{@user.id}_full_export.json", hash_data)
  end

  def json_export
    Files.json_write_to_tmp_path("#{@user.id}_json_export_#{Time.now.to_i}.json", hash_data)
  end

  def sql_export
    puts "SQL data lines is #{sql_data.length}"
    files_size = Files.raw_write(sql_export_name, sql_data.join("**EOL**"))
    puts "Exported: #{sql_export_name}, #{files_size} bytes"
    sql_export_name
  end

  def sql_export_name
    @sql_export_name ||= "#{Files.tmp_path}#{@user.id}_sql_export_#{Time.now.to_i}.sql"
  end

  def sql_data
    @sql_data ||= begin
      Polo.explore(User, @user.id, [{:subscribers => [:delivery_notices, :subscriber_responses]}, :channel_groups, {:channels => [:subscriptions, {:messages => [:action, :message_options,:subscriber_responses, :delivery_notices, :response_actions => :action]}]}])
    end
  end

  def hash_data
    @hash_data ||= begin
      hd = {}
      hd['User'] = convert_to_hash(@user)
      hd['Channel'] = convert_to_hash(channels)
      hd['DeliveryNotice'] = convert_to_hash(delivery_notices)
      hd['ChannelGroup'] = convert_to_hash(channel_groups)
      hd['Subscriber'] = convert_to_hash(subscribers)
      hd['DeliveryNotice'] = convert_to_hash(delivery_notices)
      hd['SubscriberActivity'] = convert_to_hash(subscriber_activities)
      hd['Message'] = convert_to_hash(messages)
      hd['MessageOption'] = convert_to_hash(message_options)
      hd['ResponseAction'] = convert_to_hash(response_actions)
      hd['Action'] = {}
      hd['Action']['ResponseAction'] = convert_to_hash(response_action_actions)
      hd['Action']['Message'] = convert_to_hash(message_actions)
      hd
    end
  end

  def convert_to_hash(items)
    Array(items).map { |item| item.attributes }
  end

  def channels
    @channels ||= @user.channels
  end

  def channel_groups
    @channel_groups ||= @user.channels
  end

  def subscribers
    @subscribers ||= @user.subscribers
  end

  def messages
    @messages ||= Message.where(:channel_id => channel_ids)
  end

  def response_actions
    ResponseAction.where(:message_id => message_ids)
  end

  def response_action_actions
    Action.where(:actionable_type => 'ResponseAction').where(:actionable_id => response_actions_ids)
  end

  def message_actions
    Action.where(:actionable_type => 'Message').where(:actionable_id => message_ids)
  end

  def response_actions_ids
    @reponse_actions_ids ||= response_actions.all.pluck(:id)
  end

  def message_options
    MessageOption.where(:message_id => message_ids)
  end

  def channel_ids
    @channel_ids ||= channels.all.pluck(:id)
  end

  def subscriber_ids
    @hannel_ids ||= subscribers.all.pluck(:id)
  end

  def message_ids
    @message_ids ||= messages.all.pluck(:id)
  end

  def subscriptions
    Subscription.where(:channel_id => channel_ids)
  end

  def delivery_notices
    DeliveryNotice.where(:subscriber_id => subscriber_ids)
  end

  def subscriber_activities
    SubscriberResponse.where(:subscriber_id => subscriber_ids)
  end

end
