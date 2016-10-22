source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails', '4.2.7.1'
gem 'activeresource' # active_resource/reailtie (http://stackoverflow.com/questions/16782198/cannot-load-railtie-after-upgrade-to-rails-4-per-ruby-railstutorial-org)
gem 'pg'
gem 'jquery-rails'
gem 'simple_form'
gem 'devise'
gem 'figaro'
gem 'slim-rails'

# assets and layouts
gem 'bootstrap-sass', '3.3.7'
gem 'draper' # , '>= 3.0.0.pre1' # decorators for messages and other items
gem 'font-awesome-sass', '~> 4.6.2'

gem 'json', '1.8.3'
gem 'hash_dot'

gem 'paperclip'
gem 'aws-sdk'

gem 'twilio-ruby'
gem 'will_paginate-bootstrap', '0.2.5'

gem 'sidekiq'
gem 'sidekiq-failures'

gem 'statsd-instrument'

gem 'sinatra'
gem 'clockwork'

gem 'cocoon'
gem 'chronic'
gem 'foreman'

gem 'ice_cube'
gem 'recurring_select', :git => "https://github.com/omalab/recurring_select.git", :branch => "add_hour_and_minute_to_rules"
gem 'momentjs-rails', '>= 2.9.0'
gem 'bootstrap3-datetimepicker-rails', '~> 4.17.42'
gem 'select2-rails'
gem 'moment_timezone-rails'
gem 'paranoia', '2.1.5' # 345 compatiblity

# web server
gem 'thin'

# Yaml-DB allows us to to db: load nad db:dump
gem 'yaml_db'

# Rails 4 compabilitiy wtih Rails 3 stuff, should be refactored and
# removed over time
gem 'protected_attributes'
gem 'rails-observers'
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'
gem 'activerecord-deprecated_finders'

group :development, :test do
  gem 'rspec-rails','3.5.2' # greater than Rails 3.0
  gem 'factory_girl_rails'
  gem 'spork-rails'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'annotate'
  gem 'database_cleaner'
  gem 'rspec-preloader'
  gem 'meta_request'
  gem 'pry'
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara',    '2.10.1'
  gem 'poltergeist', '1.11.0'
  gem 'faker'
  gem 'timecop'
  gem 'simplecov', require: false
  gem 'recursive-open-struct'
  gem 'rack-test', require: 'rack/test'
  gem 'test-unit'
end

group :assets, :test do
  gem 'therubyracer', '0.12.2'  # Used by twitter bootstrap for less compilation
  gem 'sass-rails',   '5.0.6'  # works up to rails 5, requires beta version for rails 5
  gem 'coffee-rails', '4.2.1'  # works up to Rails 5, needs beta versio for rails 5
  gem 'uglifier',     '3.0.2'  # requires rspec
end

# make sure you look at this, there is something with docker nad rails 5
# and this gem in heroku/non-heroku env if I remember correctly
# group :production do
#   gem 'rails_12factor'
# end
