require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { size: 1, url: ENV["REDIS_URL"] }
end

Sidekiq.configure_server do |config|
  # The config.redis is calculated by the
  # concurrency value so you do not need to
  # specify this. For this demo I do
  # show it to understand the numbers
  database_url = ENV['REDIS_URL']
  if database_url
    ENV['DATABASE_URL'] = "#{database_url}?pool=4"
    ActiveRecord::Base.establish_connection
  end
  config.redis = { size: 9, url: ENV['REDIS_URL'] }
end
