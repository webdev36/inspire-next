require 'spec_helper'

describe MessageFactory do
  it 'reads and writes a messsage back on itself without change' do
    m = create :message
    factory = MessageFactory.new({}, m.channel, m)
    expect(factory.message.save).to be_truthy
  end

  it 'creates a simple messsage from params' do
    @channel = create :channel
    params = Files.json_read_from_fixture_path('utils/message_factory/simple_message_params.json')
    factory = MessageFactory.new(params, @channel)
    expect(factory.message.save).to be_truthy
  end

  it 'updates a message from params changes' do
    @channel = create :channel
    params = Files.json_read_from_fixture_path('utils/message_factory/simple_message_params.json')
    factory = MessageFactory.new(params, @channel)
    msg2 = factory.message
    msg2.save
    params['message']['caption'] = 'This is a new caption'
    params['message']['id'] = msg2.id
    factory = MessageFactory.new(params, @channel, msg2)
    msg3 = factory.message
    expect(msg3.save).to be_truthy
    expect(msg3.caption == 'This is a new caption').to be_truthy
  end

  it 'creates tag messages' do
    @channel = create :channel
    params = Files.json_read_from_fixture_path('utils/message_factory/new_tag_message_params.json')
    factory = MessageFactory.new(params, @channel)
    msg = factory.message
    expect(msg.save).to be_truthy
    expect(msg.message_options.length == 2).to be_truthy
  end

  it 'updates tag messages with message_options' do
    @channel = create :channel
    params = Files.json_read_from_fixture_path('utils/message_factory/new_tag_message_params.json')
    factory = MessageFactory.new(params, @channel)
    msg = factory.message
    expect(msg.save).to be_truthy
    params = Files.json_read_from_fixture_path('utils/message_factory/update_tag_message_params.json')
    params['message']['message_options_attributes']['0']['id'] = msg.message_options[0].id.to_s
    params['message']['message_options_attributes']['1']['id'] = msg.message_options[1].id.to_s
    params['id'] = msg.id.to_s
    params['channel_id'] = @channel.id.to_s
    factory = MessageFactory.new(params, @channel, msg)
    msg2 = factory.message
    expect(msg2.save).to be_truthy
    sad_value = msg2.message_options.where(:key => 'sad').first.value
    expect(sad_value == "i am really really sad").to be_truthy
  end

  it 'creates a switch channel action message' do
    @channel = create :channel
    params = Files.json_read_from_fixture_path('utils/message_factory/new_action_switch_message_params.json')
    params['channel_id'] = @channel.id
    factory = MessageFactory.new(params, @channel)
    msg = factory.message
    expect(msg.save).to be_truthy
    expect(!msg.action.nil?).to be_truthy
  end

  it 'updates a switch channel action message' do
    @channel = create :channel
    params = Files.json_read_from_fixture_path('utils/message_factory/new_action_switch_message_params.json')
    params['channel_id'] = @channel.id
    factory = MessageFactory.new(params, @channel)
    msg = factory.message
    expect(msg.save).to be_truthy
    expect(!msg.action.nil?).to be_truthy
    params = Files.json_read_from_fixture_path('utils/message_factory/update_switch_channel_action_params.json')
    params['id'] = msg.id
    params['channel_id'] = @channel.id
    params['to_channel_out_group'] = ['1', '2', '3', '4']
    params['message']['action_attributes']['id'] = msg.action.id
    factory = MessageFactory.new(params, @channel, msg)
    msg2 = factory.message
    expect(msg2.save).to be_truthy
    expect(msg2.action.data['to_channel_out_group'].include?(1)).to be_truthy
  end

  context 'recurring schedules'
    context 'daily' do
      context 'at 8am' do
        xit 'created'
        xit 'updated'
      end
      context 'every other day' do
        xit 'created'
        xit 'updated'
      end
    end
    context 'weekly' do
      context 'mondays at 945a' do
        it 'is created' do
          @channel = create :channel
          params = Files.json_read_from_fixture_path('utils/message_factory/new_recurring_simple_message_params.json')
          params['channel_id'] = @channel.id
          factory = MessageFactory.new(params, @channel)
          msg = factory.message
          expect(msg.save).to be_truthy
          expect(msg.recurring_schedule[:rule_type] == 'IceCube::WeeklyRule').to be_truthy
          expect(msg.recurring_schedule[:interval] == 1).to be_truthy
          expect(msg.recurring_schedule[:validations][:hour_of_day] == [9]).to be_truthy
          expect(msg.recurring_schedule[:validations][:minute_of_hour] == [45]).to be_truthy
        end
        xit 'is updated'
      context 'every other monday at 945am' do
        xit 'created'
        xit 'updated'
      end
      context 'every monday and friday at 8am' do
        xit 'created'
        xit 'updated'
      end
    end
    context 'monthly' do
      context '1st of the month at 8am' do
        xit 'created'
        xit 'updated'
      end
      context '1st and 15 of the month at 8am' do
        xit 'created'
        xit 'updated'
      end
    end
  end
end
