require_relative '../client/client.rb'
require_relative '../verify/verify.rb'

c = Client.new("your_api_key", "your_api_secret")
v = Verify.send(c,["your_recipient_number"])
puts v
