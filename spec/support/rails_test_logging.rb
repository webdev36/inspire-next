
RSpec.configure do |config|
  # turn off SQL logging (or turn it on)
  ::ActiveRecord::Base.logger = nil
  # turn off all logging
  Rails.logger = Logger.new(STDOUT)
  # set the logger level
  Rails.logger.level = Logger::INFO
end
