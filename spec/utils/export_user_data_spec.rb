require 'spec_helper'
require 'fileutils'

describe ExportUserData do
  let(:user)      { create :user }

  xit 'exports a data element with yaml information correctly' do
    subscriber = create :subscriber
    channel = build :individually_scheduled_messages_channel, user: user
    channel.tparty_keyword = '+12025551212'
    channel.save
    message = create :message, channel: channel
    message1 = create :switch_channel_action_message, channel: channel
    message.options['one'] = 'two'
    message.options['three'] = 'four'
    message.caption = 'This is a message'
    message1.action.data["one"] = 'two'
    expect(message.save).to be_truthy
    expect(message1.save).to be_truthy
    exporter = ExportUserData.new(user)
    file_name = exporter.sql_export

    Message.with_deleted.all.each { |record| record.really_destroy! }
    Channel.with_deleted.all.each { |record| record.really_destroy! }
    Action.with_deleted.all.each  { |record| record.really_destroy! }
    User.all.each                 { |record| record.destroy }

    expect(Message.only_deleted.count == 0).to be_truthy
    importer = ImportSqlUserData.new(file_name)
    resp = importer.sql_import
    expect(Message.find(message.id).options["one"] == 'two').to be_truthy
    expect(Message.find(message1.id).action.data["one"] == 'two').to be_truthy
    FileUtils.rm(file_name)
  end

end
