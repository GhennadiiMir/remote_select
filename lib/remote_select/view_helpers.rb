module RemoteSelect
  module ViewHelpers
    # Renders a remote-data searchable select for a Rails form.
    #
    # @param form      [ActionView::Helpers::FormBuilder] Rails form builder
    # @param attribute [Symbol]  model attribute (becomes the hidden field name)
    # @param endpoint  [String]  URL that returns JSON { results: [...], has_more: bool }
    # @param options   [Hash]    see below
    #
    # Options:
    #   :selected_value            [String/Integer] pre-selected value id
    #   :selected_text             [String]         pre-selected display text
    #   :min_chars                 [Integer]        chars needed before search fires (default: 2)
    #   :debounce_delay            [Integer]        debounce in ms (default: 250)
    #   :placeholder               [String]         i18n: remote_select.placeholder
    #   :per_page                  [Integer]        results per page (default: 20)
    #   :depends_on                [String]         CSS selector(s) of dependency field(s)
    #   :clear_on_dependency_change [Boolean]       clear on dependency change (default: true)
    #   :empty_text                [String]         i18n: remote_select.empty_text
    #   :loading_text              [String]         i18n: remote_select.loading_text
    #   :html                      [Hash]           extra HTML attrs for the hidden input
    #
    def remote_select(form, attribute, endpoint, options = {})
      selected_value = options.delete(:selected_value) || form.object.try(attribute)
      selected_text  = options.delete(:selected_text)
      html_options   = options.delete(:html) || {}

      data_attrs = {
        remote_select:  true,
        endpoint:       endpoint,
        selected_value: selected_value,
        selected_text:  selected_text
      }

      data_attrs[:placeholder]  = options[:placeholder]  || I18n.t("remote_select.placeholder",  default: "Type to search...")
      data_attrs[:empty_text]   = options[:empty_text]   || I18n.t("remote_select.empty_text",   default: "No results found")
      data_attrs[:loading_text] = options[:loading_text] || I18n.t("remote_select.loading_text", default: "Loading...")

      %i[min_chars debounce_delay per_page depends_on].each do |key|
        data_attrs[key] = options[key] if options[key].present?
      end

      unless options[:clear_on_dependency_change].nil?
        data_attrs[:clear_on_dependency_change] = options[:clear_on_dependency_change]
      end

      html_options[:data] ||= {}
      html_options[:data].merge!(data_attrs)
      html_options[:class] = [html_options[:class], "remote-select-input"].compact.join(" ")

      form.hidden_field(attribute, html_options)
    end
  end
end
