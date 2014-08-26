require File.expand_path(File.dirname(__FILE__) + '/../app.rb')
require "minitest/autorun"

class SignatureTest < Minitest::Test
  def setup
    @app = OffsiteGatewaySim.new
  end

  def test_signature_has_no_influence_on
    assert @app
  end
end
