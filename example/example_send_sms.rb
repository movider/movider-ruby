require_relative '../client/client.rb'
require_relative '../sms/sms.rb'

c = Client.new("your_api_key", "your_api_secret")
s = SMS.send(c,["your_recipient_number"],"your_message_id")
puts s
