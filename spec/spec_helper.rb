require 'rubygems'
require 'spork'
require 'timecop'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  unless ENV['DRB']
    #require 'simplecov'
    # SimpleCov.start
  end

  require 'rails/application'
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!)

  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'capybara/rspec'
  require 'capybara/poltergeist'
  require 'sidekiq/testing'
  require 'rspec/autorun'
  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
  RSpec.configure do |config|
    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = "random"

    config.include FactoryGirl::Syntax::Methods
    config.include Devise::TestHelpers, type: :controller

    config.before(:suite) do
      DatabaseCleaner.clean_with(:truncation)
    end

    config.before(:each) do
      DatabaseCleaner.start
      $original_time = Time.now
    end

    config.before(:suite) do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
    end

    config.after(:each) do
      Timecop.return
      DatabaseCleaner.clean
    end

    config.before(:each) do
      Sidekiq::Worker.clear_all
    end

  end
  Rails.logger.level = Logger::DEBUG
  Capybara.javascript_driver = :poltergeist
  include LoginMacros
end

Spork.each_run do
  if ENV['DRB']
    # require 'simplecov'
    # SimpleCov.start 'rails'
  end
  FactoryGirl.reload
  ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
end
