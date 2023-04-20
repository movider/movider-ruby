require_relative '../client/client.rb'
require 'json'

class ResultVerify
  attr_accessor :request_id, :number, :price

  def initialize(request_id, number, price)
    @request_id = request_id
    @number = number
    @price = price
  end
end

class ResultAcknowledge
  attr_accessor :request_id, :price

  def initialize(request_id, price)
    @request_id = request_id
    @price = price
  end
end

class ResultCancel
  attr_accessor :request_id

  def initialize(request_id)
    @request_id = request_id
  end
end



def make_send_request_data(client, to: nil, request_id: nil, code: nil, parameters: nil)
  data = {
    "api_key" => client.api_key,
    "api_secret" => client.api_secret
  }

  data["to"] = to.join(",") if to

  data["request_id"] = request_id if request_id

  data["code"] = code if code


  if parameters
    data["code_length"] = parameters.code_length if parameters.code_length

    data["language"] = parameters.language if parameters.language

    data["pinExpire"] = parameters.pin_expire if parameters.pin_expire

    data["from"] = parameters.from if parameters.from
  end

  data
end

class Verify
  attr_accessor :result, :error

  def initialize(result: nil, error: nil)
    @result = result
    @error = error
  end
  def to_s
    if @result.instance_of?(ResultVerify)
      return "Request ID: #{@result.request_id}, Number: #{@result.number}, Price: #{@result.price}"
    elsif @result.instance_of?(ResultAcknowledge)
      return "Request ID: #{@result.request_id}, Price: #{@result.price}"
    elsif @result.instance_of?(ResultCancel)
      return "Request ID: #{@result.request_id} cancelled"
    end

    if @error != nil
      return "Error: #{@error["name"]} (#{@error['code']}) - #{@error['description']}"
    else
      return "Unknown result type"
    end
  end

  def self.send(client, to, parameters = nil)
    raise "Invalid client parameter" if client.nil? || !client.is_a?(Client)

    raise "Invalid to parameter" if to.nil? || to.empty?

    to.each do |phone|
      raise "Invalid phone number in to parameter" if phone.empty?
    end

    parameters ||= Params.new

    endpoint = client.endpoint + VERIFY_URI_PATH
    data = make_send_request_data(client, to: to, parameters: parameters)
    response = client.request(endpoint, data)

    status_code = response[:code]
    body = response[:content]
    result = JSON.parse(body)

    if status_code != "200"
      error = result["error"]
      return Verify.new(error: error)
    end

    result = ResultVerify.new(result["request_id"], result["number"], result["price"])
    Verify.new(result: result)
  end

  def self.sendAcknowledge(client, code, request_id)
    raise "Invalid client parameter" if client.nil? || !client.is_a?(Client)

    raise "Invalid parameter" if code.nil? || request_id.empty?


    endpoint = client.endpoint + VERIFY_URI_PATH + VERIFY_ACK_PATH
    data = make_send_request_data(client,code:code, request_id:request_id)
    response = client.request(endpoint, data)

    status_code = response[:code]
    body = response[:content]
    if status_code != "200"
      result = JSON.parse(body)
      error = result["error"]
      return Verify.new(error: error)
    end

    result = JSON.parse(body)
    result = ResultAcknowledge.new(result["request_id"], result["number"], result["price"])
    Verify.new(result: result)
  end

  def self.cancel(client, request_id)
    raise "Invalid client parameter" if client.nil? || !client.is_a?(Client)

    raise "Invalid parameter" if request_id.nil?


    endpoint = client.endpoint + VERIFY_URI_PATH + VERIFY_CAN_PATH
    data = make_send_request_data(client, request_id:request_id)
    response = client.request(endpoint, data)

    status_code = response[:code]
    body = response[:content]
    if status_code != "200"
      result = JSON.parse(body)
      error = result["error"]
      return Verify.new(error: error)
    end

    result = JSON.parse(body)
    result = ResultCancel.new(result["request_id"], result["number"], result["price"])
    Verify.new(result: result)
  end

end

VERIFY_URI_PATH = "/verify"
VERIFY_ACK_PATH = "/acknowledge"
VERIFY_CAN_PATH = "/cancel"
