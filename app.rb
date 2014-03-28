require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'httparty'
require 'json'
require 'addressable/uri'
require 'byebug' if development?

class OffsiteGatewaySim < Sinatra::Base

  def initialize
    @key = 'iU44RWxeik'
    super
  end

  def fields
    @fields ||= request.params.select {|k, v| k.start_with? 'x-'}
  end

  def sign(fields)
    Digest::HMAC.hexdigest(fields.sort.join, @key, Digest::SHA256)
  end

  post '/' do
    signature_ok = sign(fields.reject{|k,_| k == 'x-signature'}) == fields['x-signature']
    erb :index, :locals => {signature_ok: signature_ok}
  end

  post '/execute/:action' do |action|
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
    payload['x-signature'] = sign(payload)
    result = {timestamp: ts}
    redirect_url = Addressable::URI.parse(fields['x-url-complete'])
    redirect_url.query_values = payload
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

  run! if app_file == $0

end
