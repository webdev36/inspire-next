# use this to make live calls in development mode
if Rails.env != 'production'
  puts "MOCK calls are enabled. API calls logged to Rails.root/tmp folder."
  TwilioWrapper.mock_calls = true
else
  puts "LIVE CALLS ARE ENABLED. You will send messages to subscribers."
end
