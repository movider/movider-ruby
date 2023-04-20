require_relative '../client/client.rb'
require 'json'


class PhoneNumber
  attr_accessor :number, :message_id, :price

  def initialize(number, message_id, price)
    @number = number
    @message_id = message_id
    @price = price
  end

  def to_s
    "{Number: #{@number}, Message ID: #{@message_id}, Price: #{@price}}"
  end
end

class BadNumber
  attr_accessor :number, :msg

  def initialize(number, msg)
    @number = number
    @msg = msg
  end

  def to_s
    "{Number: #{@number}, Message: #{@msg}}"
  end
end

class ResultSms
  attr_accessor :remaining_balance, :total_sms, :phone_number_list, :bad_phone_number_list, :schedule_id

  def initialize(remaining_balance, total_sms, phone_number_list, bad_phone_number_list, schedule_id = nil)
    @remaining_balance = remaining_balance
    @total_sms = total_sms
    @phone_number_list = phone_number_list
    @bad_phone_number_list = bad_phone_number_list
    @schedule_id = schedule_id
  end
end

class ResultSchedule
  attr_accessor :id, :text, :total_sms, :method, :callback_url, :from, :delivery_date, :delivery_status, :delivery_status_update_date, :created_date

  def initialize(obj)
    @id = obj["id"]
    @text = obj["text"]
    @total_sms = obj["total_sms"]
    @method = obj["method"]
    @callback_url = obj["callback_url"]
    @from = obj["from"]
    @delivery_date = obj["delivery_date"]
    @delivery_status = obj["delivery_status"]
    @delivery_status_update_date = obj["delivery_status_updated_date"]
    @created_date = obj["created_date"]
  end
end

SMS_URI_PATH = "/sms"
SCH_URI_PATH = "/scheduled"
class SMS
  attr_accessor :result, :error

  def initialize(result: nil, error: nil)
    @result = result
    @error = error
  end

  def to_s
    if @result.is_a?(ResultSms)
      txt = "Remaining Balance: #{@result.remaining_balance}, Total SMS: #{@result.total_sms}"
      phone_number_list = @result.phone_number_list.map { |pn| pn.to_s }.join(", ")
      txt += ", Phone number: [#{phone_number_list}]"
      bad_phone_number_list = @result.bad_phone_number_list.map { |bn| bn.to_s }.join(", ")
      txt += ", Bad phone number: [#{bad_phone_number_list}]" unless bad_phone_number_list.empty?
      txt += ", ScheduleId: #{@result.schedule_id}" unless result.schedule_id.nil?
      return txt
  elsif @result.is_a?(Array) && @result.first.is_a?(ResultSchedule)
    txt = ""
    @result.each do |schedule|
      txt += "Id: #{schedule.id}, Text: #{schedule.text}, TotalSms: #{schedule.total_sms}, "
      txt += "Method: #{schedule.method}, CallbackUrl: #{schedule.callback_url}, FromNumber: #{schedule.from}, "
      txt += "DeliveryDate: #{schedule.delivery_date}, DeliveryStatus: #{schedule.delivery_status}, "
      txt += "DeliveryStatusUpdateDate: #{schedule.delivery_status_update_date}, CreatedDate: #{schedule.created_date}\r\n"
    end
    txt
  elsif @result.is_a?(ResultSchedule)
    txt = "Id: #{@result.id}, Text: #{@result.text}, TotalSms: #{@result.total_sms}, "
    txt += "Method: #{@result.method}, CallbackUrl: #{@result.callback_url}, FromNumber: #{@result.from}, "
    txt += "DeliveryDate: #{@result.delivery_date}, DeliveryStatus: #{@result.delivery_status}, "
    txt += "DeliveryStatusUpdateDate: #{@result.delivery_status_update_date}, CreatedDate: #{@result.created_date}"
  elsif @result.is_a?(String)
    @result
    end
      if @error != nil
      return "Error: #{@error["name"]} (#{@error['code']}) - #{@error['description']}"
  else
      return "Unknown result type"
    end
  end
# Sends SMS using a specified client object, phone numbers, text, and optional parameters.
#
# @param client [Client, nil] A client object for sending SMS messages.
# @param to [Array] An array of phone numbers to send SMS message.
# @param text [String] The body text of the SMS message.
# @param parameters [Params, nil] An optional object of parameters to send along with the SMS message.
# @return [SMS] An object containing any errors or a ResultSms object containing the sent and failed message data.
# @raise [Exception] If the client is not a valid Mvdclient object or to parameter is invalid.

  def self.send(client,to,text,params = nil)
    raise "Invalid client parameter" if client.nil? || !client.is_a?(Client)

    raise "Invalid to parameter" if to.nil? || to.empty?

    to.each do |phone|
      raise "Invalid phone number in to parameter" if phone.empty?
    end

    parameters ||= Params.new

    endpoint = client.endpoint + SMS_URI_PATH
    data = make_send_request_data(client,to:to,text:text,parameters:parameters)
    response = client.request(endpoint,data)
    status_code = response[:code]
    body = response[:content]
    result = JSON.parse(body)
    if status_code != "200"
        error = result["error"]
        return SMS.new(error:error)
    end

    phone_number_list = []
    result["phone_number_list"].each do |pnl|
        phone_number_list.push(PhoneNumber.new(pnl["number"], pnl["message_id"], pnl["price"]))
    end

    bad_phone_number_list = []
    result["bad_phone_number_list"].each do |bpl|
        bad_phone_number_list.push(BadNumber.new(bpl["number"], bpl["msg"]))
    end

    result_sms = ResultSms.new(result["remaining_balance"], result["total_sms"], phone_number_list, bad_phone_number_list)
    SMS.new(result: result_sms)
  end

# Send SMS message on a specific date and time to a list of phone numbers
#
# @param client [Client] The Mvdclient object used to make the request
# @param to [Array] The list of phone numbers to send to
# @param delivery_datetime [String] The date and time the message should be sent
# @param text [String] The text to be sent
# @param parameters [Params, nil] The parameters to use for the request, default is nil
# @return [SMS] The SMS object containing the result of the operation
# @raise [Exception] Throws an exception if an invalid parameter is passed

  def self.sendScheduled(client,to,delivery_datetime,text,params = nil)
    raise "Invalid client parameter" if client.nil? || !client.is_a?(Client)

    raise "Invalid to parameter" if to.nil? || to.empty?

    raise "Invalid string parameter" if text.nil? || delivery_datetime.nil?

    to.each do |phone|
      raise "Invalid phone number in to parameter" if phone.empty?
    end

    parameters ||= Params.new

    endpoint = client.endpoint + SMS_URI_PATH + SCH_URI_PATH
    data = make_send_request_data(client,to:to,delivery_datetime:delivery_datetime,text:text,parameters:parameters)
    response = client.request(endpoint,data)
    status_code = response[:code]
    body = response[:content]
    result = JSON.parse(body)
    if status_code != "200"
        error = result["error"]
        return SMS.new(error:error)
    end
    phone_number_list = []
    result["phone_number_list"].each do |pnl|
        phone_number_list.push(PhoneNumber.new(pnl["number"], pnl["message_id"], pnl["price"]))
    end

    bad_phone_number_list = []
    result["bad_phone_number_list"].each do |bpl|
        bad_phone_number_list.push(BadNumber.new(bpl["number"], bpl["msg"]))
    end

    result_sms = ResultSms.new(result["remaining_balance"], result["total_sms"], phone_number_list, bad_phone_number_list, schedule_id:result["scheduleId"])
    SMS.new(result: result_sms)
  end
# Retrieves all schedules for a given client.
#
# @param client [Client] The client parameter.
# @return [SMS] Returns an instance of SMS with the list of schedules or an error message.
# @raise [Exception] Throws an Exception with a message "Invalid client parameter" if the client parameter is nil or not an instance of Mvdclient.

  def self.getAllSchedule(client)
    raise "Invalid client parameter" if client.nil? || !client.is_a?(Client)

    url = client.endpoint + SMS_URI_PATH + SCH_URI_PATH
    response = client.get(url)
    status_code = response[:code]
    body = response[:content]
    result = JSON.parse(body)
    if status_code != "200"
        error = result["error"]
        return SMS.new(error:error)
    end
    list = []
    result["items"].each do |item|
        list << ResultSchedule.new(item)
    end
    SMS.new(result: list)
  end

# Retrieves a scheduled SMS by schedule ID using given Client.
#
# @param client [Client] The Client instance to use for API requests.
# @param scheduleID [String] The ID of the scheduled SMS to retrieve.
# @return [SMS] Returns an SMS instance containing either the scheduled SMS or an error message.
# @raise [Exception] If the client parameter is invalid.

  def self.getScheduleById(client,schedule_id)
    raise "Invalid client parameter" if client.nil? || !client.is_a?(Client)

    url = "#{client.endpoint}#{SMS_URI_PATH}#{SCH_URI_PATH}/#{schedule_id}"
    response = client.get(url)
    status_code = response[:code]
    body = response[:content]
    result = JSON.parse(body)
    if status_code != "200"
        error = result["error"]
        return SMS.new(error:error)
    end
    result_schedule = ResultSchedule.new(result)
    SMS.new(result: result_schedule)
  end

  # Deletes a scheduled SMS by schedule ID using given Client.
#
# @param client [Client] The Client instance to use for API requests.
# @param scheduleID [String] The ID of the scheduled SMS to retrieve.
# @return [SMS] Returns an SMS instance containing either the scheduled SMS or an error message.
# @raise [Exception] If the client parameter is invalid.


  def self.deleteScheduled(client,schedule_id)
    raise "Invalid client parameter" if client.nil? || !client.is_a?(Client)

    url = "#{client.endpoint}#{SMS_URI_PATH}#{SCH_URI_PATH}/#{schedule_id}"
    response = client.delete(url)
    status_code = response[:code]
    body = response[:content]
    if status_code != "200"
        result = JSON.parse(body)
        error = result["error"]
        return SMS.new(error:error)
    end
   return "Delete completed successfully"
  end

end

def make_send_request_data(client, to: nil,delivery_datetime:nil, text: nil, parameters: nil)
  data = {
    "api_key" => client.api_key,
    "api_secret" => client.api_secret
  }

  data["to"] = to.join(",") if to

  data["delivery_datetime"] = delivery_datetime if delivery_datetime

  data["text"] = text if text


  if parameters
    data["code_length"] = parameters.code_length if parameters.code_length

    data["language"] = parameters.language if parameters.language

    data["pinExpire"] = parameters.pin_expire if parameters.pin_expire

    data["from"] = parameters.from if parameters.from
  end

  data
end





