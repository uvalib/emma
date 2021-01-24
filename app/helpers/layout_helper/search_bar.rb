# app/helpers/layout_helper/search_bar.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::SearchBar
#
module LayoutHelper::SearchBar

  include LayoutHelper::SearchControls
  include SearchTermsHelper
  include ConfigurationHelper
  include I18nHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A table of controllers and whether their pages should show search input in
  # the page heading.
  #
  # @type [Hash{Symbol=>Boolean,Array<String>}]
  #
  SEARCH_INPUT_ENABLED =
    ApplicationHelper::APP_CONTROLLERS.map { |controller|
      look_opt = { controller: controller, mode: false }
      enabled  = config_lookup('search_bar.enabled', **look_opt)
      enabled  = enabled.is_a?(Array) ? enabled.map(&:to_s) : true?(enabled)
      [controller, enabled]
    }.to_h.deep_freeze

  # The icon used within the search bar to clear the current search.
  #
  # @type [String]
  #
  CLEAR_SEARCH_ICON = HEAVY_X

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search bar.
  #
  # @param [Hash, nil] p              Default: `#request_parameters`.
  #
  def show_search_bar?(p = nil)
    p     ||= request_parameters
    type    = search_target(p)
    enabled = SEARCH_INPUT_ENABLED[type]
    enabled = enabled.include?(p[:action].to_s) if enabled.is_a?(Array)
    enabled
  end

  # Indicate whether it is appropriate to show the search input menu.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  #
  def show_input_select?(type = nil)
    search_input_types(type).size > 1
  end

  # Generate an element for selecting search type.
  #
  # @param [Hash] opt                 Passed to #select_tag except for:
  #                                     #MENU_OPTS
  #
  # @return [ActiveSupport::SafeBuffer] An HTML input element.
  # @return [nil]                       If search is not available for *type*.
  #
  def search_input_select(**opt)
    type = search_input_target
    return unless show_input_select?(type)
    opt, html_opt = partition_options(opt, *MENU_OPTS)
    url_param   = opt[:url_parameter] || :input_select # TODO
    multiple    = opt[:multiple]      || false
    default     = opt[:default]       || search_input_field(type)
    selected    = opt[:selected] || search_parameters.keys.presence || default
    selected    = Array.wrap(selected).map(&:to_s).uniq
    option_tags = options_for_select(search_menu_pairs, selected)
    prepend_css_classes!(html_opt, 'search-input-select')
    html_opt[:multiple] = true if multiple
    html_opt[:'aria-label'] = 'Search Type' # TODO: I18n
    select_tag(url_param, option_tags, html_opt)
  end

  # Generate an element for entering search terms.
  #
  # @param [Symbol, String, nil] id     Default: `#search_input_field(type)`
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #search_form.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML input element.
  # @return [nil]                       If search is not available for *type*.
  #
  def search_input_bar(id: nil, type: nil, **opt)
    type ||= search_input_target
    id   ||= search_input_field(type)
    return unless id && type
    skip_nav_append(search_bar_label(type) => id)
    prepend_css_classes!(opt, 'search-input-bar')
    # noinspection RubyYardParamTypeMatch
    search_form(id, type, **opt) do
      search_input(id, type) + search_button(type)
    end
  end

  # search_bar_label
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #config_lookup.
  #
  # @return [String]                    The specified value.
  # @return [nil]                       No non-empty value was found.
  #
  def search_bar_label(type = nil, **opt)
    type ||= search_input_target or return
    config_lookup('search_bar.label', controller: type, **opt)
  end

  # The URL parameter to which search terms should be applied.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #config_lookup.
  #
  # @return [String]                    The specified value.
  # @return [nil]                       No non-empty value was found.
  #
  def search_input_field(type = nil, **opt)
    # noinspection RubyYardReturnMatch
    search_input_default(type, **opt)[:field]
  end

  # Screen-reader-only label for the input field.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #config_lookup.
  #
  # @return [String]                    The specified value.
  # @return [nil]                       No non-empty value was found.
  #
  def search_input_label(type = nil, **opt)
    # noinspection RubyYardReturnMatch
    search_input_default(type, **opt)[:label]
  end

  # Placeholder text displayed in the search input box.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #config_lookup.
  #
  # @return [String]                    The specified value.
  # @return [nil]                       No non-empty value was found.
  #
  def search_input_placeholder(type = nil, **opt)
    # noinspection RubyYardReturnMatch
    search_input_default(type, **opt)[:placeholder]
  end

  # Properties of the default search input type.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #config_lookup.
  #
  # @return [Hash{Symbol=>Symbol,String}]
  #
  def search_input_default(type = nil, **opt)
    field, values = search_input_types(type, **opt).first
    values ? { field: field }.merge!(values) : {}
  end

  # All defined input types.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #config_lookup.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def search_input_types(type = nil, **opt)
    type ||= search_input_target
    config_lookup('search_type', controller: type, **opt) || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # search_input_target
  #
  # @param [Symbol, String, nil] type   Default: `params[:controller]`.
  #
  # @return [Symbol]                    The controller used for searching.
  # @return [nil]                       If search input should not be enabled.
  #
  def search_input_target(type = nil)
    type = search_target(type)
    # noinspection RubyYardReturnMatch
    type if SEARCH_INPUT_ENABLED[type]
  end

  # Generate a form search field input control.
  #
  # @param [Symbol, String, nil] id     Default: `#search_input_field(type)`
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [String, nil]         value  Default: `params[id]`.
  # @param [Hash]                opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_input(id, type, value: nil, **opt)
    type ||= search_input_target
    id   ||= search_input_field(type)
    id     = id&.to_sym
    label_id = "#{id}-label"

    # Screen-reader-only label element.
    label = search_input_label(type)
    label &&= html_span(label, id: label_id, class: 'sr-only')
    label ||= ''.html_safe

    # Input field element.
    value ||= request_parameters[id]
    value = '' if value == NULL_SEARCH
    prepend_css_classes!(opt, 'search-input')
    opt[:'aria-labelledby'] = label_id
    opt[:placeholder] ||= search_input_placeholder(type)
    input = search_field_tag(id, value, opt)

    # Control for clearing search terms.
    clear = clear_search_button

    # Result.
    # noinspection RubyYardReturnMatch
    label << input << clear
  end

  # Generate a form submit control.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [String, nil]         label  Default: `#search_button_label(type)`.
  # @param [Hash]                opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_button(type, label: nil, **opt)
    type  ||= search_input_target
    label ||= search_button_label(type)
    prepend_css_classes!(opt, 'search-button')
    submit_tag(label, opt)
  end

  # search_button_label
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #config_lookup.
  #
  # @return [String]                    The specified value.
  # @return [nil]                       No non-empty value was found.
  #
  def search_button_label(type, **opt)
    type ||= search_input_target
    config_lookup('search_bar.button.label', controller: type, **opt)
  end

  # clear_search_button
  #
  # @param [Hash] opt                 Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/advanced-search.js clearSearch()
  # @see HtmlHelper#icon_button
  #
  def clear_search_button(**opt)
    prepend_css_classes!(opt, 'search-clear')
    opt[:role]  ||= 'button'
    opt[:title] ||= 'Clear search terms' # TODO: I18n
    opt[:icon]  ||= CLEAR_SEARCH_ICON
    opt[:url]   ||= '#'
    icon_button(**opt)
  end

end

__loading_end(__FILE__)
