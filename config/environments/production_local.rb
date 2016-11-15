require 'resolv'

Liveinspired::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  config.log_level = :info
  config.lograge.enabled = true

  config.web_console.development_only = false

  config.eager_load = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = {host:'localhost:3000'}


  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict
  # rails 5 act like it now so we don't have errors later
  config.active_record.raise_in_transactional_callbacks = true

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 1

  # Do not compress assets
  config.assets.compress = false
  config.assets.compile = true
  config.assets.debug = true

  # config logger for logging, stdout only, info messages
  config.logger = Logger.new(STDOUT)
  config.log_level = :info

  # not show docker errors in the console in development mode
  config.web_console.whitelisted_ips = %w(0.0.0.0)
  config.web_console.automount = true

  config.time_zone = 'Eastern Time (US & Canada)'
end
