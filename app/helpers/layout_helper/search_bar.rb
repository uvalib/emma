# app/helpers/layout_helper/search_bar.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::SearchBar
#
module LayoutHelper::SearchBar

  include LayoutHelper::SearchControls

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search bar.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  #
  def show_search_bar?(type = nil)
    search_input_type(type).present?
  end

  # Generate an element for entering search terms.
  #
  # @param [Symbol, String, nil] id     Default: `#search_field_key(type)`
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [Hash]                opt    Passed to #search_form.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If search is not available for *type*.
  #
  def search_input_bar(id: nil, type: nil, **opt)
    type ||= search_input_type or return
    id   ||= search_field_key(type)
    skip_nav_append(search_bar_label(type) => id)
    opt = prepend_css_classes(opt, 'search-input-bar')
    search_form(id, type, **opt) do
      search_input(id, type) + search_button(type)
    end
  end

  # search_bar_label
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [Hash]                opt    Passed to #i18n_lookup.
  #
  # @return [String]
  # @return [nil]
  #
  def search_bar_label(type, **opt)
    type ||= search_input_type
    i18n_lookup(type, 'search_bar.label', **opt)
  end

  # The URL parameter to which search terms should be applied.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [Hash]                opt    Passed to #i18n_lookup.
  #
  # @return [Symbol]
  # @return [nil]
  #
  def search_field_key(type, **opt)
    type ||= search_input_type
    i18n_lookup(type, 'search_bar.input.field', **opt)&.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  extend I18nHelper

  # @type [Hash{Symbol=>Boolean}]
  SEARCH_INPUT_ENABLED =
    SEARCH_MENU_MAP.keys.map { |type|
      enabled = i18n_lookup(type, 'search_bar.input.enabled', mode: false)
      [type, enabled.present?]
    }.to_h

  # search_input_type
  #
  # @param [Symbol, String, nil] type   Default: `#params[:controller]`.
  #
  # @return [Symbol]                    The controller used for searching.
  # @return [nil]                       If search input should not be enabled.
  #
  def search_input_type(type = nil)
    type = search_type(type)
    # noinspection RubyYardReturnMatch
    type if SEARCH_INPUT_ENABLED[type]
  end

  # Generate a form search field input control.
  #
  # @param [Symbol, String, nil] id     Default: `#search_field_key(type)`
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [String, nil]         value  Default: `#params[id]`.
  # @param [Hash]                opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_input(id, type, value: nil, **opt)
    type ||= search_input_type
    id   ||= search_field_key(type)
    id   &&= id.to_sym
    label_id = "#{id}-label"

    # Screen-reader-only label element.
    label = i18n_lookup(type, 'search_bar.input.label')
    label &&= html_span(label, id: label_id, class: 'sr-only')
    label ||= ''.html_safe

    # Input field element.
    value ||= request_parameters[id]
    value = '' if value == NULL_SEARCH
    opt = prepend_css_classes(opt, 'search-input')
    opt[:'aria-labelledby'] = label_id
    opt[:placeholder] ||= i18n_lookup(type, 'search_bar.input.placeholder')
    input = search_field_tag(id, value, opt)

    # Control for clearing search terms.
    clear = clear_search_button(id: id)

    # Result.
    # noinspection RubyYardReturnMatch
    label << input << clear
  end

  # Generate a form submit control.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [String, nil]         label  Default: `#search_button_label(type)`.
  # @param [Hash]                opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_button(type, label: nil, **opt)
    type  ||= search_input_type
    label ||= search_button_label(type)
    opt = prepend_css_classes(opt, 'search-button')
    submit_tag(label, opt)
  end

  # search_button_label
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [Hash]                opt    Passed to #i18n_lookup.
  #
  # @return [String]
  # @return [nil]
  #
  def search_button_label(type, **opt)
    type ||= search_input_type
    i18n_lookup(type, 'search_bar.button.label', **opt)
  end

  # clear_search_button
  #
  # @param [Symbol, String, nil] id     Default: `#search_field_key(type)`
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [Hash]                opt    Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def clear_search_button(id: nil, type: nil, **opt)
    id ||= search_field_key(type || search_input_type)
    query_params = Array.wrap(id&.to_sym).presence || TEXT_SEARCH_PARAMETERS
    old_params   = url_parameters
    new_params   = old_params.except(*query_params)
    opt = prepend_css_classes(opt, 'search-clear')
    opt[:'aria-role'] ||= 'button'
    opt[:title]       ||= 'Clear search terms' # TODO: I18n
    link_to(HEAVY_X, url_for(new_params), opt)
  end

end

__loading_end(__FILE__)
