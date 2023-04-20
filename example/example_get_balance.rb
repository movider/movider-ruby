require_relative '../client/client.rb'
require_relative '../balance/balance.rb'

c = Client.new("your_api_key", "your_api_secret")
b = Balance.get(c)
puts b
