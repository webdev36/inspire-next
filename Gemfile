source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails', '4.0.13'
gem 'activeresource' # active_resource/reailtie (http://stackoverflow.com/questions/16782198/cannot-load-railtie-after-upgrade-to-rails-4-per-ruby-railstutorial-org)
gem 'pg'
gem 'jquery-rails'
gem 'simple_form'
gem 'devise'
gem 'twitter-bootstrap-rails'
gem 'figaro'


gem 'json', '1.8.3'
gem 'kaminari'

gem 'paperclip'
gem 'aws-sdk'

gem 'twilio-ruby'
gem 'will_paginate-bootstrap', '0.2.5'

gem 'sidekiq'
gem 'sinatra'
gem 'clockwork'

gem 'cocoon'
gem 'chronic'
gem 'foreman'

gem 'ice_cube'
gem 'recurring_select', :git => "https://github.com/omalab/recurring_select.git", :branch => "add_hour_and_minute_to_rules"
gem 'datetimepicker-rails', :require => 'datetimepicker-rails', :git => 'https://github.com/zpaulovics/datetimepicker-rails.git'
gem 'paranoia', '2.1.5' # 345 compatiblity

gem 'thin'

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
end

group :test do
  gem 'capybara'
  gem 'poltergeist', '1.10.0'
  gem 'faker'
  gem 'timecop'
  gem 'simplecov', require: false
  gem 'recursive-open-struct'
  gem 'rack-test', require: 'rack/test'
  gem 'test-unit'
end

group :assets do
  gem 'sass-rails',   '5.0.6' # works up to rails 5, requires beta version for rails 5
  gem 'coffee-rails', '4.2.1' # works up to Rails 5, needs beta versio for rails 5
  gem 'uglifier',     '3.0.2' # requires rspec
  gem 'therubyracer' #Used by twitter bootstrap for less compilation
  gem 'less-rails'   #Used by twitter bootstrap for customization
end

# make sure you look at this, there is something with docker nad rails 5
# and this gem in heroku/non-heroku env if I remember correctly
group :production do
  gem 'rails_12factor'
end
