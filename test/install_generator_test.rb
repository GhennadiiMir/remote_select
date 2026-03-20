require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "json"

# Load Rails generator infrastructure
require "rails/generators"
require "rails/generators/testing/behavior"
require "rails/generators/testing/assertions"

require_relative "../lib/remote_select/version"
require_relative "../lib/remote_select/engine"
require_relative "../lib/generators/remote_select/install_generator"

class RemoteSelect::InstallGeneratorTest < Minitest::Test
  include Rails::Generators::Testing::Behavior
  include Rails::Generators::Testing::Assertions
  include FileUtils

  tests RemoteSelect::Generators::InstallGenerator

  def self.test_destination
    @test_destination ||= File.expand_path("../tmp/generator_test", __dir__)
  end

  destination test_destination

  def setup
    prepare_destination
    # Create minimal directory structure that a Rails app would have
    FileUtils.mkdir_p(File.join(destination_root, "app/javascript"))
    FileUtils.mkdir_p(File.join(destination_root, "app/assets/stylesheets"))
  end

  # ── Copies JS file ────────────────────────────────────────────────────

  def test_copies_javascript_file
    run_generator
    assert_file "app/javascript/remote_select.js"
  end

  def test_javascript_has_version_comment
    run_generator
    assert_file "app/javascript/remote_select.js", /remote_select v#{Regexp.escape(RemoteSelect::VERSION)}/
  end

  def test_javascript_contains_remote_select_class
    run_generator
    assert_file "app/javascript/remote_select.js", /class RemoteSelect/
  end

  # ── Copies CSS file ───────────────────────────────────────────────────

  def test_copies_stylesheet
    run_generator
    assert_file "app/assets/stylesheets/remote_select.css"
  end

  def test_stylesheet_has_version_comment
    run_generator
    assert_file "app/assets/stylesheets/remote_select.css", /remote_select v#{Regexp.escape(RemoteSelect::VERSION)}/
  end

  def test_stylesheet_contains_container_styles
    run_generator
    assert_file "app/assets/stylesheets/remote_select.css", /\.remote-select-container/
  end

  # ── Skip if file exists (no --force) ──────────────────────────────────

  def test_skips_existing_javascript_without_force
    # Pre-create file
    File.write(File.join(destination_root, "app/javascript/remote_select.js"), "// existing")

    run_generator
    # File should still have original content
    assert_equal "// existing", File.read(File.join(destination_root, "app/javascript/remote_select.js"))
  end

  def test_skips_existing_stylesheet_without_force
    File.write(File.join(destination_root, "app/assets/stylesheets/remote_select.css"), "/* existing */")

    run_generator
    assert_equal "/* existing */", File.read(File.join(destination_root, "app/assets/stylesheets/remote_select.css"))
  end

  # ── Overwrites with --force ────────────────────────────────────────────

  def test_overwrites_javascript_with_force
    File.write(File.join(destination_root, "app/javascript/remote_select.js"), "// old")

    run_generator ["--force"]
    content = File.read(File.join(destination_root, "app/javascript/remote_select.js"))
    assert_match(/class RemoteSelect/, content)
  end

  def test_overwrites_stylesheet_with_force
    File.write(File.join(destination_root, "app/assets/stylesheets/remote_select.css"), "/* old */")

    run_generator ["--force"]
    content = File.read(File.join(destination_root, "app/assets/stylesheets/remote_select.css"))
    assert_match(/\.remote-select-container/, content)
  end

  # ── Pipeline detection ────────────────────────────────────────────────

  def test_detects_importmap
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/importmap.rb"), 'pin "application"')

    output = run_generator
    assert_match(/importmap/i, output)
  end

  def test_detects_esbuild
    File.write(File.join(destination_root, "package.json"),
      JSON.generate({ "devDependencies" => { "esbuild" => "^0.17" } }))

    output = run_generator
    assert_match(/esbuild/i, output)
  end

  def test_detects_cssbundling_sass
    File.write(File.join(destination_root, "package.json"),
      JSON.generate({ "scripts" => { "build:css" => "sass ./app/assets/stylesheets" } }))

    output = run_generator
    assert_match(/sass/i, output)
  end
end
