# use this to make live calls in development mode
if Rails.env == 'development'
  puts "MOCK Calls are Enabled. Calls will be sent to the TSV file in the Rails.root"
  TwilioWrapper.mock_calls = true
end
