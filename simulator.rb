require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'httparty'
require 'json'
require 'byebug'
require "addressable/uri"

post '/' do
  erb :index
end

post '/execute/:action' do |action|
  key = 'iU44RWxeik'
  fields = request.params.select {|k, v| k.start_with? 'x-'}
  ts = Time.now.utc.iso8601
  payload = {
    'x-id'                => fields['x-id'],
    'x-reference'         => fields['x-reference'],
    'x-currency'          => fields['x-currency'],
    'x-test'              => fields['x-test'],
    'x-amount'            => fields['x-amount'],
    'x-result'            => action,
    'x-gateway-reference' => SecureRandom.hex,
    'x-timestamp'         => ts
    }
  payload['x-signature'] = Digest::HMAC.hexdigest(payload.sort.join, key, Digest::SHA1)

  result = {timestamp: ts}
  redirect_url = Addressable::URI.parse(fields['x-url-complete'])
  redirect_url.query_values = payload
  debugger
  if request.params['fire_callback'] == 'true'
    callback_url = fields['x-url-callback']
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
