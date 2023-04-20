require 'uri'
require 'net/http'
require 'openssl'

class Client
  attr_accessor :api_key, :api_secret
  attr_reader :endpoint, :content_type_json, :content_type_form_urlencoded

  def initialize(api_key, api_secret)
    @api_key = api_key
    @api_secret = api_secret
    @endpoint = "https://mvd-sms-api.ngrok.1mobyline.com/v1"
    @content_type_json = "application/json"
    @content_type_form_urlencoded = "application/x-www-form-urlencoded"
  end

  def request(url, data)
    raise TypeError, "Invalid input type" unless url.is_a?(String) && data.is_a?(Hash)

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request["accept"] = @content_type_json
    request["content-type"] = @content_type_form_urlencoded
    request.body = URI.encode_www_form(data)
    response = http.request(request)
    {
      code: response.code,
      content: response.body
    }
  end

  def get(url)
  uri = URI.parse(url + "?api_key=#{self.api_key}&api_secret=#{self.api_secret}")
  response = Net::HTTP.get_response(uri)
  {
    code: response.code,
    content: response.body
  }
end

def delete(url)
  uri = URI.parse(url + "?api_key=#{self.api_key}&api_secret=#{self.api_secret}")
  request = Net::HTTP::Delete.new(uri)
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  {
    code: response.code,
    content: response.body
  }
end
end

class Params
  attr_accessor :code_length, :language, :pin_expire, :from, :callback_url, :callback_method

  def initialize(code_length: nil, language: nil, pin_expire: nil, from: nil, callback_url: nil, callback_method: nil)
    @code_length = code_length
    @language = language
    @pin_expire = pin_expire
    @from = from
    @callback_url = callback_url
    @callback_method = callback_method
  end
end
