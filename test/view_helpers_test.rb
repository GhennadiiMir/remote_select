require "minitest/autorun"
require "action_view"
require "action_view/helpers"
require "active_model"

# Minimal Rails-like setup for testing outside a full Rails app
require_relative "../lib/remote_select/version"
require_relative "../lib/remote_select/view_helpers"

# Stub I18n if not loaded by action_view
unless defined?(I18n) && I18n.respond_to?(:t)
  module I18n
    def self.t(key, default: nil, **_opts)
      default
    end
  end
end

class RemoteSelect::ViewHelpersTest < Minitest::Test
  include RemoteSelect::ViewHelpers
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormTagHelper

  # ── Fake model + builder ────────────────────────────────────────────────

  class FakeArticle
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :company_id, :integer
    attribute :city_id, :integer

    def company_id; @company_id end
    def company_id=(v); @company_id = v end
  end

  def build_form(object = FakeArticle.new)
    ActionView::Helpers::FormBuilder.new(:article, object, self, {})
  end

  # ActionView needs these to render
  def protect_against_forgery?; false end
  def output_buffer; @output_buffer ||= ActionView::OutputBuffer.new end
  def output_buffer=(buf); @output_buffer = buf end

  # ── Tests ───────────────────────────────────────────────────────────────

  def test_renders_hidden_field_with_data_attributes
    form = build_form
    html = remote_select(form, :company_id, "/companies/search")

    assert_match 'type="hidden"', html
    assert_match 'name="article[company_id]"', html
    assert_match 'data-remote-select="true"', html
    assert_match 'data-endpoint="/companies/search"', html
  end

  def test_includes_remote_select_input_class
    form = build_form
    html = remote_select(form, :company_id, "/search")

    assert_match 'class="remote-select-input"', html
  end

  def test_preselected_value_from_option
    form = build_form
    html = remote_select(form, :company_id, "/search",
      selected_value: 42,
      selected_text: "Acme Corp")

    assert_match 'data-selected-value="42"', html
    assert_match 'data-selected-text="Acme Corp"', html
  end

  def test_preselected_value_falls_back_to_model_attribute
    article = FakeArticle.new
    article.company_id = 99
    form = build_form(article)
    html = remote_select(form, :company_id, "/search")

    assert_match 'value="99"', html
  end

  def test_custom_placeholder
    form = build_form
    html = remote_select(form, :company_id, "/search",
      placeholder: "Find a company...")

    assert_match 'data-placeholder="Find a company..."', html
  end

  def test_min_chars_option
    form = build_form
    html = remote_select(form, :company_id, "/search", min_chars: 3)

    assert_match 'data-min-chars="3"', html
  end

  def test_debounce_delay_option
    form = build_form
    html = remote_select(form, :company_id, "/search", debounce_delay: 500)

    assert_match 'data-debounce-delay="500"', html
  end

  def test_per_page_option
    form = build_form
    html = remote_select(form, :company_id, "/search", per_page: 50)

    assert_match 'data-per-page="50"', html
  end

  def test_depends_on_option
    form = build_form
    html = remote_select(form, :city_id, "/search",
      depends_on: "#country-selector")

    assert_match 'data-depends-on="#country-selector"', html
  end

  def test_clear_on_dependency_change_false
    form = build_form
    html = remote_select(form, :city_id, "/search",
      depends_on: "#country",
      clear_on_dependency_change: false)

    assert_match 'data-clear-on-dependency-change="false"', html
  end

  def test_custom_html_attributes
    form = build_form
    html = remote_select(form, :company_id, "/search",
      html: { id: "my-select", data: { turbo: false } })

    assert_match 'id="my-select"', html
    assert_match 'data-turbo="false"', html
  end

  def test_default_i18n_texts
    form = build_form
    html = remote_select(form, :company_id, "/search")

    assert_match 'data-placeholder="Type to search..."', html
    assert_match 'data-empty-text="No results found"', html
    assert_match 'data-loading-text="Loading..."', html
  end

  def test_custom_empty_and_loading_text
    form = build_form
    html = remote_select(form, :company_id, "/search",
      empty_text: "Nothing here",
      loading_text: "Please wait...")

    assert_match 'data-empty-text="Nothing here"', html
    assert_match 'data-loading-text="Please wait..."', html
  end

  def test_html_class_merges_with_existing
    form = build_form
    html = remote_select(form, :company_id, "/search",
      html: { class: "my-custom-class" })

    assert_match "my-custom-class", html
    assert_match "remote-select-input", html
  end
end
