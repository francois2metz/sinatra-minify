require 'helper'

class TestMinify < Test::Unit::TestCase
  def app
    App
  end

  def output
    last_response.body
  end

  should "rock pants off" do
    get '/'
    assert_match "Hello", output
  end

  should "Include all scripts" do
    get '/foo'
    assert_match /script-1.js/, output
    assert_match /script-2.js/, output
  end

  describe "In a production environment" do
    def setup
      app.enable :force_minify
    end

    def teardown
      app.disable :force_minify
    end

    should "Include the minified script" do
      get '/foo'
      assert_match /base.min.js\?/, output
    end
  end
end
