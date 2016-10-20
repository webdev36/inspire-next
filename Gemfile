source 'https://rubygems.org'

ruby '1.9.3'

gem 'rails', '3.2.15'
gem 'pg'
gem 'jquery-rails'
gem 'simple_form'
gem 'devise'
gem 'twitter-bootstrap-rails'
gem 'figaro'

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
gem 'recurring_select', :git => "https://github.com/vbabu75/recurring_select.git", :branch => "add_hour_and_minute_to_rules"
gem 'datetimepicker-rails', :require => 'datetimepicker-rails', :git => 'https://github.com/zpaulovics/datetimepicker-rails.git'
gem 'paranoia', "~> 1.0"

gem 'rails_admin'
gem 'thin'

group :development, :test do
  gem 'rspec-rails','~> 2.0'
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
  gem 'simplecov', :require=>false
  gem 'recursive-open-struct'
  gem 'rack-test', :require=>"rack/test"
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'therubyracer' #Used by twitter bootstrap for less compilation
  gem 'less-rails'   #Used by twitter bootstrap for customization
end

group :production do
  gem 'rails_12factor'
end
