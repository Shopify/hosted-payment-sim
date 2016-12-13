ENV['RACK_ENV'] = 'test'

require_relative '../app'
require 'test/unit'
require 'rack/test'
require 'yaml'

class OffsiteGatewaySimTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    OffsiteGatewaySim
  end

  RESPONSE_FIELDS = {
    x_account_id: 'test123',
    x_reference: '12345',
    x_currency: 'USD',
    x_test: true,
    x_amount: 89.99,
    x_gateway_reference: 123,
    x_timestamp: '2014-03-24T12:15:41Z'
  }

  REQUEST_FIELDS = begin
    YAML.load_file('request_fields.yml').each.inject({}) do |h, field|
      h[field['key']] = field['placeholder']
      h
    end
  end

  def test_get_root
    get '/'
    assert last_response.ok?
    assert_equal 200, last_response.status
  end

  def test_get_calculator
    get '/calculator'
    assert last_response.ok?
  end

  def test_post_root_signature_validation
    fields  = RESPONSE_FIELDS.merge(
      some_param:   'a_param_that_should_be_excluded',
      x_result:     'completed',
      x_signature:  '2edd2a8f13d810560b7c09dd02c9b331f97961c0f5733b66b354ff5fa9da4716'
    )

    post '/', fields
    assert last_response.ok?
    assert last_response.body.include?('yes.png'), 'Signature\'s do not match'
  end

  def test_post_completed
    post 'execute/completed', REQUEST_FIELDS
    assert last_response.ok?
    assert last_response.body.include?('completed')
  end

  def test_post_failed_with_custom_message
    post 'execute/failed', REQUEST_FIELDS
    assert last_response.ok?
    assert last_response.body.include?('failed')
    assert last_response.body.include?('x_message')
  end

  def test_post_successful_refund
    fields = RESPONSE_FIELDS.merge(
      x_transaction_type: 'refund',
      x_signature: '1fab8337eae73be8e3090d5a89a2b40630e1e44a4e85ff1a2d08e3da662fd1c7'
    )

    expected_response_keys = [
      'x_account_id',
      'x_reference',
      'x_currency',
      'x_test',
      'x_amount',
      'x_gateway_reference',
      'x_timestamp',
      'x_transaction_type',
      'x_signature',
      'x_status'
    ]

    post '/refund', fields
    assert last_response.ok?
    assert_equal 200, last_response.status
    last_response.body.include?('success')
    assert_equal 'application/json', last_response.header['content-type']
    assert expected_response_keys.all? { |k| JSON.parse(last_response.body).key? k }
  end

  def test_post_failed_refund
    fields = RESPONSE_FIELDS.merge(
      x_transaction_type: 'refund',
      x_signature: 'incorrect'
    )

    post '/refund', fields
    assert_equal 401, last_response.status
    last_response.body.include?('failed')
  end
end
