# app/helpers/layout_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper methods supporting general page layout.
#
module LayoutHelper::Common

  include Emma::Common
  include Emma::Constants

  include HtmlHelper
  include ParamsHelper
  include SearchTermsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for panel properties.
  #
  # @type [Hash{Symbol=>Any}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  PANEL_CONFIG = I18n.t('emma.panel', default: {}).deep_freeze

  # Label for button to open a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_OPENER_LABEL =
    non_breaking(PANEL_CONFIG.dig(:control, :label)).html_safe.freeze

  # Tooltip for button to open a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_OPENER_TIP = PANEL_CONFIG.dig(:control, :tooltip)

  # Label for button to close a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_CLOSER_LABEL =
    non_breaking(PANEL_CONFIG.dig(:control, :open, :label)).html_safe.freeze

  # Tooltip for button to close a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_CLOSER_TIP = PANEL_CONFIG.dig(:control, :open, :tooltip)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # toggle_button
  #
  # @param [String] id                HTML element controlled by this button.
  # @param [String, nil] label        Default: #PANEL_OPENER_LABEL.
  # @param [String, nil] selector     Selector of the element controlled by
  #                                     this button (only used if panel.js
  #                                     RESTORE_PANEL_STATE is *true*).
  # @param [Hash] opt                 Passed to #button_tag.
  #
  # @raise [RuntimeError]             The controlled element was not specified.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/panel.js
  #
  def toggle_button(id:, label: nil, selector: nil, **opt)
    css_selector  = '.toggle'
    opt[:type]  ||= 'button'
    opt[:title] ||= PANEL_OPENER_TIP
    opt[:'aria-controls'] = id       if id.present?
    opt[:'data-selector'] = selector if selector.present?
    raise 'no target id given' if opt[:'aria-controls'].blank?
    if opt[:'data-selector'].present? && opt[:data].is_a?(Hash)
      opt[:data] = opt[:data].except(:selector)
    end
    label = label ? non_breaking(label) : PANEL_OPENER_LABEL
    button_tag(label, prepend_classes!(opt, css_selector))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # If the client is responsible for managing hidden inputs on forms then they
  # should not be generated via #search_form.
  #
  # @type [Boolean]
  #
  CLIENT_MANAGES_HIDDEN_INPUTS = true

  def search_form(target, id = nil, hidden: nil, **opt, &block)
    search_form_with_hidden(target, id, hidden: hidden, **opt, &block)
  end unless CLIENT_MANAGES_HIDDEN_INPUTS

  # A form used to create/modify a search.
  #
  # @param [Symbol, String, nil] target
  # @param [Symbol, String, nil] id       @note [1]
  # @param [Hash, nil]           hidden   note [1]
  # @param [Hash]                opt      Passed to #html_form.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML form element.
  # @return [nil]                         Search is not available for *target*.
  #
  # @yield To supply additional field(s) for the <form>.
  # @yieldreturn [String, Array<String>]
  #
  # @note [1] If #CLIENT_MANAGES_HIDDEN_INPUTS then id and hidden are ignored.
  #
  #++
  # noinspection RubyUnusedLocalVariable
  #--
  def search_form(target, id = nil, hidden: nil, **opt, &block)
    return if (path = search_target_path(target)).blank?
    opt[:method] ||= :get
    html_form(path, opt, &block)
  end if CLIENT_MANAGES_HIDDEN_INPUTS

  # A form used to create/modify a search.
  #
  # When searching via the indicated *target*, and *id* is supplied then the
  # current URL parameters are included as hidden fields so that the current
  # search is repeated but augmented with the added parameter.
  #
  # Otherwise a new search is assumed.
  #
  # @param [Symbol, String, nil] target
  # @param [Symbol, String, nil] id       Passed to #hidden_parameter_for.
  # @param [Hash, nil]           hidden   Passed to #hidden_parameter_for.
  # @param [Hash]                opt      Passed to #html_form.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML form element.
  # @return [nil]                         Search is not available for *target*.
  #
  # @yield To supply additional field(s) for the <form>.
  # @yieldreturn [String, Array<String>]
  #
  # @note Used only if #CLIENT_MANAGES_HIDDEN_INPUTS is false.
  #
  def search_form_with_hidden(target, id = nil, hidden: nil, **opt)
    return if (path = search_target_path(target)).blank?
    include_hidden = hidden.present? || (id.present? && (path == request.path))
    before, after = (hidden_parameters_for(id, hidden) if include_hidden)
    elements = [*before, *yield, *after]
    opt[:method] ||= :get
    html_form(path, *elements, opt)
  end

  # Create sets of hidden fields to accompany the *id* field.
  #
  # The field names are sorted so that the method returns zero or more
  # '<input type="hidden">' elements which should be inserted before the *id*
  # field and zero or more elements that should be inserted after.
  #
  # This ensures that the resulting search URL will be generated with
  # parameters in a consistent order.
  #
  # @param [Symbol, String, nil] id
  # @param [Hash, nil]           fields   Default: based on #url_parameters
  #
  # @return [Array<(Array,Array)>]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def hidden_parameters_for(id, fields = nil)
    id     = id.presence&.to_sym
    fields = fields&.symbolize_keys || url_parameters
    fields = fields.except!(id, *NON_SEARCH_KEYS).sort
    before_after = id ? fields.partition { |k, _| k <= id } : [fields, []]
    before_after.each { |a| a.map! { |k, v| hidden_input(k, v, id: id) } }
  end

  # Generate a hidden <input> which indicates a parameter for the new search
  # URL that will result from the associated facet value being removed from the
  # current search.
  #
  # @param [Symbol, String]      k
  # @param [String, Array]       v
  # @param [Symbol, String, nil] id
  # @param [String]              separator
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def hidden_input(k, v, id: nil, separator: "\n")
    id = [id, k].compact_blank.join('-')
    if v.is_a?(Array)
      v.map.with_index(1) { |value, index|
        hidden_field_tag("#{k}[]", value, id: "#{id}-#{index}")
      }.join(separator).html_safe
    else
      hidden_field_tag(k, v, id: id)
    end
  end

  # The target path for searches from the search bar.
  #
  # @param [Symbol, String, nil] target   Default: #DEFAULT_SEARCH_CONTROLLER
  # @param [Hash]                opt      Passed to #url_for.
  #
  # @return [String]
  #
  def search_target_path(target = nil, **opt)
    target ||= DEFAULT_SEARCH_CONTROLLER
    ctrlr    = "/#{target}"
    action   = nil
    action ||= ('v2' if v2_style?)
    action ||= ('v3' if v3_style?)
    action ||= SEARCH_CONTROLLERS[target&.to_sym]
    url_for(opt.merge(controller: ctrlr, action: action, only_path: true))
  rescue ActionController::UrlGenerationError
    search_target_path(**opt)
  end

end

__loading_end(__FILE__)
