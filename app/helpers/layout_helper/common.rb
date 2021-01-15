# app/helpers/layout_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::Common
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
  # @type [Hash{Symbol=>*}]
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
  # @raise [StandardError]            The controlled element was not specified.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see app/assets/javascripts/feature/panel.js
  #
  def toggle_button(id:, label: nil, selector: nil, **opt)
    prepend_css_classes!(opt, 'toggle')
    opt[:'aria-controls'] = id       if id.present?
    opt[:'data-selector'] = selector if selector.present?
    raise 'no target id given' if opt[:'aria-controls'].blank?
    if opt[:'data-selector'].present? && opt[:data].is_a?(Hash)
      opt[:data] = opt[:data].except(:selector)
    end
    label = label ? non_breaking(label) : PANEL_OPENER_LABEL
    opt[:type]  ||= 'button'
    opt[:title] ||= PANEL_OPENER_TIP
    button_tag(label, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A form used to create/modify a search.
  #
  # If currently searching for the indicated *type*, then the current URL
  # parameters are included as hidden fields so that the current search is
  # repeated but augmented with the added parameter.  Otherwise a new search is
  # assumed.
  #
  # Hidden fields are sorted by name with those before *id* included before the
  # content provided via the block, and with those whose names sort later than
  # *id* included after the content provided by the block.  This ensures that
  # the resulting search URL will be generated with parameters in a consistent
  # order.
  #
  # @param [Symbol, String] id
  # @param [Symbol, String] type
  # @param [Hash]           opt       Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML form element.
  # @return [nil]                       If search is not available for *type*.
  #
  # @yield To supply additional field(s) for the <form>.
  # @yieldreturn [String, Array<String>]
  #
  def search_form(id, type, **opt)
    return if (path = search_target_path(type)).blank?
    opt[:method] ||= :get
    before, after =
      if path == request.path
        hidden_fields = url_parameters.except(id, :offset, :start).sort
        hidden_fields.partition { |k, _| k.to_s <= id.to_s }.each do |hidden|
          hidden.map! { |k, v| hidden_url_parameter(id, k, v) }
        end
      end
    form_tag(path, opt) do
      [*before, *yield, *after].join("\n").html_safe
    end
  end

  # Generate a hidden <input> which indicates a parameter for the new search
  # URL that will result from the associated facet value being removed from the
  # current search.
  #
  # @param [Symbol, String, nil] id
  # @param [Symbol, String]      k
  # @param [String, Array]       v
  # @param [String]              separator
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def hidden_url_parameter(id, k, v, separator: "\n")
    id = [id, k].reject(&:blank?).join('-')
    if v.is_a?(Array)
      i = 0
      v = v.map { |e| hidden_field_tag("#{k}[]", e, id: "#{id}-#{i += 1}") }
      safe_join(v, separator)
    else
      hidden_field_tag(k, v, id: id)
    end
  end

  # The target path for searches from the search bar.
  #
  # @param [Symbol, String] type
  # @param [Hash]           opt       Passed to #url_for.
  #
  # @return [String]
  #
  def search_target_path(type, **opt)
    controller = "/#{type}"
    action     = SEARCH_CONTROLLERS[type]
    url_for(opt.merge(controller: controller, action: action, only_path: true))
  rescue ActionController::UrlGenerationError
    search_target_path(DEFAULT_SEARCH_CONTROLLER, **opt)
  end

end

__loading_end(__FILE__)
