require_relative '../client/client.rb'
require 'json'

class ResultBalance
  attr_reader :type, :amount

  def initialize(type, amount)
    @type = type
    @amount = amount
  end
end

BALANCE_URI_PATH = '/balance'

class Balance
  attr_reader :result, :error

  def initialize(result = nil, error = nil)
    @result = result
    @error = error
  end

  def to_s
    if @result
        result_balance = @result[:result]
        return "Type: #{result_balance.type}, Amount: #{result_balance.amount}"
    elsif @error != nil
      return "Error: #{@error["name"]} (#{@error['code']}) - #{@error['description']}"
    else
        return "Error: Unknown error"
    end
    else
      return "Unknown result type"
    end
  end

  def self.get(client)
    raise TypeError, 'client parameter must be an instance of Client class' unless client.is_a?(Client)

    url = client.endpoint + BALANCE_URI_PATH

    response = client.request(url, 'api_key' => client.api_key, 'api_secret' => client.api_secret)
    status_code = response[:code]
    body = response[:content]
    if status_code != "200"
      error = JSON.parse(body,object_class: OpenStruct)['error']
      return new(error: error)
    end
    result =  JSON.parse(body,object_class: OpenStruct)
    result = ResultBalance.new(result['type'], result['amount'])
    new(result: result)
  end
end
