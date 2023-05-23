# Movider Client Library for Ruby

Movider API client for Ruby. API support for SMS, Verify, Balance
<img align="right" width="159px" src="https://movider.co/icons/icon-144x144.png">

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

## Installation

Ruby need to be installed

```bash
$ruby -v
ruby 3.2.2
```

## Usage/Examples

Assuming package has been installed. You can import Client class like this:

```ruby
require_relative '../client/client.rb'

c = Client.new("your_api_key", "your_api_secret")
```

if you don't have api_key and api_secret, [Sign up](https://dashboard.movider.co/sign-up) Movider's account to use.

### Get Balance

Retreiving current balance in your account.Starting by import the Movider's balance package

```ruby
require_relative '../balance/balance.rb'

```

then get the current balance and display it

```ruby
b = Balance.get(c)
puts b
```

### Send SMS

Send an outbound SMS from your Movider's account. Starting by import the Movider's SMS package like this

```ruby
require_relative '../sms/sms.rb'
```

then send the sms and display the result

```ruby
s = SMS.send(c,["your_recipient_number"],"your_message_text")
puts s

```

your-recipient-number are specified numbers in E.164 format such as 66812345678, 14155552671.

## Documentation

Complete documentation, instructions, and examples are available at [https://movider.co](https://movider.co)

## License

Movider client library for Ruby is licensed under [The MIT License](./LICENSE). Copyright (c) 2019 1Moby Co.,Ltd
