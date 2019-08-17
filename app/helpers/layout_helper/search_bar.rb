# app/helpers/layout_helper/search_bar.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::SearchBar
#
module LayoutHelper::SearchBar

  include GenericHelper
  include HtmlHelper
  include I18nHelper
  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search bar.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [Hash, nil]           p      Default: `#params`.
  #
  def show_search_bar?(type = nil, p = nil)
    search_input_type(type, p).present?
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
  def search_bar(id: nil, type: nil, **opt)
    type ||= search_input_type
    return if type.blank?
    opt  = prepend_css_classes(opt, 'search-bar')
    id ||= search_field_key(type)
    skip_nav_append(search_bar_label(type) => id)
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
  def search_bar_label(type = nil, **opt)
    type ||= search_input_type
    i18n_lookup(type, 'search_bar.label', **opt)
  end

  # The URL parameter to which search terms should be applied.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  #
  # @return [String]
  # @return [nil]
  #
  def search_field_key(type = nil)
    type ||= search_input_type
    i18n_lookup(type, 'search_bar.input.field')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # search_input_type
  #
  # @param [Symbol, String, nil] type   Default: `#params[:controller]`.
  # @param [Hash, nil]           p      Default: `#params`.
  #
  # @return [String]                  The controller used for searching.
  # @return [FalseClass]              If searching should not be enabled.
  #
  def search_input_type(type = nil, p = nil)
    if p
      type ||= p[:controller]
      value = i18n_lookup(type, 'search_bar.input.enabled')
      # noinspection RubyYardReturnMatch
      !false?(value) && (true?(value) ? type.to_s : 'title')
    elsif @search_input_type.nil?
      @search_input_type = search_input_type(type, params)
    else
      @search_input_type
    end
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
  def search_input(id = nil, type = nil, value = nil, **opt)
    type ||= search_input_type
    id   ||= search_field_key(type)
    label_id = "#{id}-label"

    # Screen-reader-only label element.
    label = i18n_lookup(type, 'search_bar.input.label')
    label &&= content_tag(:span, label, id: label_id, class: 'sr-only')
    label ||= ''.html_safe

    # Input field element.
    opt = prepend_css_classes(opt, 'search-input')
    opt[:'aria-labelledby'] = label_id
    opt[:placeholder] ||= i18n_lookup(type, 'search_bar.input.placeholder')
    input = search_field_tag(id, (value || params[id]), opt)

    # Result.
    label + input
  end

  # Generate a form submit control.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [String, nil]         label  Default: `#search_button_label(type)`.
  # @param [Hash]                opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_button(type = nil, label = nil, **opt)
    type  ||= search_input_type
    label ||= search_button_label(type)
    opt = prepend_css_classes(opt, 'search-button')
    # noinspection RubyYardReturnMatch
    submit_tag(label, opt)
  end

  # search_button_label
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  # @return [nil]
  #
  def search_button_label(type)
    i18n_lookup(type, 'search_bar.button.label')
  end

end

__loading_end(__FILE__)
