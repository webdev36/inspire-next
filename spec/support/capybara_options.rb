require 'spec_helper'

RSpec.configure do |config|
  Capybara.javascript_driver = :poltergeist
  config.before(:each, js: true) do
    resize_window_to(1600,1600)
  end
end
