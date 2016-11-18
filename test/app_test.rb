ENV['RACK_ENV'] = 'test'

require_relative '../app'
require 'test/unit'
require 'rack/test'

class OffsiteGatewaySimTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    OffsiteGatewaySim.new!
  end

  FIELDS = {
    x_account_id: 'test123',
    x_reference: '12345',
    x_currency: 'USD',
    x_test: true,
    x_amount: 89.99,
    x_gateway_reference: 123,
    x_timestamp: '2014-03-24T12:15:41Z'
  }

  def test_get_root
    get '/'
    assert last_response.ok?
  end

  def test_get_calculator
    get '/calculator'
    assert last_response.ok?
  end

  def test_signing_mechanism
    assert_equal("933b8f5ea6bf362a677ff433555cdbb1b723185a1e8e1ce6b2d7b6a6d325dc88", app.sign(FIELDS, "iU44RWxeik"))
  end

  def test_post_root_signature_validation
    fields  = FIELDS.merge(
      some_param:   'a_param_that_should_be_excluded',
      x_result:     'completed',
      x_signature:  '2edd2a8f13d810560b7c09dd02c9b331f97961c0f5733b66b354ff5fa9da4716'
    )

    post '/', fields
    assert last_response.ok?
    assert last_response.body.include?('yes.png'), "Signature's do not match"
  end

  def test_post_successful_refund
    fields = FIELDS.merge(
      x_transaction_type: "refund",
      x_signature: '1fab8337eae73be8e3090d5a89a2b40630e1e44a4e85ff1a2d08e3da662fd1c7'
    )

    post '/refund', fields
    assert last_response.ok?
    last_response.body.include?('success')
  end

  def test_post_failed_refund
    fields = FIELDS.merge(
      x_transaction_type: "refund",
      x_signature: 'incorrect'
    )
    
    post '/refund', fields
    assert_equal 401, last_response.status
    last_response.body.include?('failed')
  end
end
