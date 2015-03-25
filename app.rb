require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'httparty'
require 'json'
require 'addressable/uri'
require 'byebug' if development?

class OffsiteGatewaySim < Sinatra::Base

  def initialize(base_path: '')
    @base_path = base_path
    @key = 'iU44RWxeik'
    super
  end

  def fields
    @fields ||= request.params.select {|k, v| k.start_with? 'x_'}
  end

  def request_fields
    YAML.load_file('request_fields.yml')
  end

  def response_fields
    YAML.load_file('response_fields.yml')
  end

  def sign(fields, key=@key)
    Digest::HMAC.hexdigest(fields.sort.join, key, Digest::SHA256)
  end

  get '/' do
    erb :get, :locals => {key: @key}
  end

  post '/' do
    provided_signature = fields['x_signature']
    expected_signature = sign(fields.reject{|k,_| k == 'x_signature'})
    signature_ok = provided_signature && provided_signature.casecmp(expected_signature) == 0
    erb :post, :locals => {signature_ok: signature_ok}
  end

  get '/calculator' do
    erb :calculator, :locals => {
      request_fields: request_fields,
      response_fields: response_fields,
      signature: sign(fields.delete_if { |_, v| v.nil? }, params['secret_key'] || @key)
    }
  end

  post '/execute/:action' do |action|
    ts = Time.now.utc.iso8601
    payload = {
      'x_account_id'        => fields['x_account_id'],
      'x_reference'         => fields['x_reference'],
      'x_currency'          => fields['x_currency'],
      'x_test'              => fields['x_test'],
      'x_amount'            => fields['x_amount'],
      'x_result'            => action,
      'x_gateway_reference' => SecureRandom.hex,
      'x_timestamp'         => ts
      }
    payload['x_signature'] = sign(payload)
    result = {timestamp: ts}
    redirect_url = Addressable::URI.parse(fields['x_url_complete'])
    redirect_url.query_values = payload
    if request.params['fire_callback'] == 'true'
      callback_url = fields['x_url_callback']
      response = HTTParty.post(callback_url, body: payload)
      if response.code == 200
        result[:redirect] = redirect_url
      else
        result[:error] = response
      end
    else
      result[:redirect] = redirect_url
    end
    result.to_json
  end

  run! if app_file == $0

end
