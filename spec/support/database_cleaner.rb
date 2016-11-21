require 'spec_helper'

# database cleaning cleans up databases between tests

RSpec.configure do |config|
  # do not use transactional fixtures IF you are using DatabaseCleaner according to Rsppec
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
  end

  config.before(:each) do
    DatabaseCleaner.clean
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end
end
