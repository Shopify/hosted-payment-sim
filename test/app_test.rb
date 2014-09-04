ENV['RACK_ENV'] = 'test'

require_relative '../app'
require 'test/unit'
require 'rack/test'

class OffsiteGatewaySimTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    OffsiteGatewaySim
  end

  def test_get_root
    get '/'
    assert last_response.ok?
  end

end
