require "minitest/autorun"

# Tests that verify the JS source contains expected patterns.
# These are static analysis tests — they ensure the JS file hasn't regressed
# on critical features without requiring a browser or Node.js runtime.
class RemoteSelect::JavaScriptSourceTest < Minitest::Test
  def setup
    @js_path = File.expand_path("../app/javascript/remote_select.js", __dir__)
    @js = File.read(@js_path)
  end

  # ── Select2 compatibility ─────────────────────────────────────────────

  def test_accepts_has_more_pagination
    assert_match(/data\.has_more/, @js, "JS should read data.has_more")
  end

  def test_accepts_select2_pagination_more
    assert_match(/data\.pagination\?\.more/, @js, "JS should read data.pagination?.more")
  end

  def test_pagination_uses_nullish_coalescing
    assert_match(/has_more \?\? data\.pagination/, @js,
      "Pagination should use ?? (nullish coalescing) not || to handle false correctly")
  end

  # ── XSS safety ────────────────────────────────────────────────────────

  def test_results_use_text_content_not_inner_html
    # The _renderResults method should use textContent for user data
    assert_match(/item\.textContent\s*=\s*result\.text/, @js,
      "Results must use textContent (not innerHTML) to prevent XSS")
  end

  # ── Turbo integration ─────────────────────────────────────────────────

  def test_listens_to_domcontentloaded
    assert_match(/DOMContentLoaded/, @js)
  end

  def test_listens_to_turbo_load
    assert_match(/turbo:load/, @js)
  end

  def test_listens_to_turbo_frame_load
    assert_match(/turbo:frame-load/, @js)
  end

  def test_cleanup_before_turbo_render
    assert_match(/turbo:before-render/, @js)
  end

  # ── Exports ───────────────────────────────────────────────────────────

  def test_esm_export
    assert_match(/export\s*\{\s*RemoteSelect\s*\}/, @js)
  end

  def test_default_export
    assert_match(/export default RemoteSelect/, @js)
  end

  def test_global_window_export
    assert_match(/window\.RemoteSelect\s*=\s*RemoteSelect/, @js)
  end

  # ── ARIA ──────────────────────────────────────────────────────────────

  def test_combobox_role
    assert_match(/role.*combobox/, @js)
  end

  def test_listbox_role
    assert_match(/role.*listbox/, @js)
  end

  def test_aria_expanded
    assert_match(/aria-expanded/, @js)
  end

  # ── AbortController ──────────────────────────────────────────────────

  def test_uses_abort_controller
    assert_match(/AbortController/, @js, "Fetch should use AbortController for cancellation")
  end

  # ── Version header ───────────────────────────────────────────────────

  def test_version_header_present
    first_line = @js.lines.first
    assert_match(/remote_select v\d+\.\d+\.\d+/, first_line,
      "JS file should have a version header on the first line")
  end
end
