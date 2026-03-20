require "minitest/autorun"

require_relative "../lib/remote_select/version"

class RemoteSelect::VersionTest < Minitest::Test
  def test_version_is_defined
    refute_nil RemoteSelect::VERSION
  end

  def test_version_is_semver
    assert_match(/\A\d+\.\d+\.\d+\z/, RemoteSelect::VERSION)
  end

  def test_version_is_0_2_0
    assert_equal "0.2.0", RemoteSelect::VERSION
  end
end
