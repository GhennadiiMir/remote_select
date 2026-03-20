require "minitest/autorun"
require "rails"
require "rails/engine"

require_relative "../lib/remote_select/version"
require_relative "../lib/remote_select/engine"

class RemoteSelect::EngineTest < Minitest::Test
  def test_engine_is_a_rails_engine
    assert RemoteSelect::Engine < ::Rails::Engine
  end

  def test_engine_root_contains_app_directory
    root = RemoteSelect::Engine.root
    assert root.join("app/javascript/remote_select.js").exist?,
      "Expected remote_select.js in engine app/javascript/"
    assert root.join("app/assets/stylesheets/remote_select.css").exist?,
      "Expected remote_select.css in engine app/assets/stylesheets/"
  end

  def test_engine_is_isolated
    assert_equal "remote_select", RemoteSelect::Engine.engine_name
  end
end
