require 'open-uri'
require 'net/http'


params = {'Body' => 'Hello', 'From' => '+14089876512', 'To'=>'+14082345678'}
url = URI.parse('http://localhost:3000/twilio')
resp, data = Net::HTTP.post_form(url, params)
puts resp.inspect
puts data.inspect