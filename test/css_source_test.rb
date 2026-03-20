require "minitest/autorun"

# Tests that verify the CSS source contains expected patterns.
class RemoteSelect::CssSourceTest < Minitest::Test
  def setup
    @css_path = File.expand_path("../app/assets/stylesheets/remote_select.css", __dir__)
    @css = File.read(@css_path)
  end

  # ── Custom properties available for theming ───────────────────────────

  def test_defines_text_color_variable
    assert_match(/--rs-text-color/, @css)
  end

  def test_defines_bg_color_variable
    assert_match(/--rs-bg-color/, @css)
  end

  def test_defines_border_color_variable
    assert_match(/--rs-border-color/, @css)
  end

  def test_defines_focus_border_variable
    assert_match(/--rs-focus-border-color/, @css)
  end

  def test_defines_focus_shadow_variable
    assert_match(/--rs-focus-shadow/, @css)
  end

  def test_defines_zindex_variable
    assert_match(/--rs-zindex/, @css)
  end

  def test_defines_dropdown_max_height_variable
    assert_match(/--rs-dropdown-max-height/, @css)
  end

  # ── Key selectors exist ───────────────────────────────────────────────

  def test_container_class
    assert_match(/\.remote-select-container/, @css)
  end

  def test_trigger_class
    assert_match(/\.remote-select-trigger/, @css)
  end

  def test_dropdown_class
    assert_match(/\.remote-select-dropdown/, @css)
  end

  def test_search_class
    assert_match(/\.remote-select-search/, @css)
  end

  def test_results_class
    assert_match(/\.remote-select-results/, @css)
  end

  def test_item_class
    assert_match(/\.remote-select-item/, @css)
  end

  def test_is_open_shows_dropdown
    assert_match(/\.remote-select-container\.is-open\s+\.remote-select-dropdown/, @css)
  end

  # ── Version header ───────────────────────────────────────────────────

  def test_version_header_present
    first_line = @css.lines.first
    assert_match(/remote_select v\d+\.\d+\.\d+/, first_line,
      "CSS file should have a version header on the first line")
  end

  # ── Responsive ───────────────────────────────────────────────────────

  def test_has_responsive_media_query
    assert_match(/@media/, @css, "CSS should include responsive breakpoints")
  end
end
