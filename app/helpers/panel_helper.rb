# app/helpers/panel_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the creation of collapsible panels.
#
module PanelHelper

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for panel control properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection, RubyMismatchedConstantType
  #++
  PANEL_CTRL_CFG = I18n.t('emma.panel.control', default: {}).deep_freeze

  # Label for button to open a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_OPENER_LABEL =
    non_breaking(PANEL_CTRL_CFG.dig(:label)).html_safe.freeze

  # Tooltip for button to open a collapsible panel.
  #
  # @type [String]
  #
  PANEL_OPENER_TIP = PANEL_CTRL_CFG.dig(:tooltip)

  # Label for button to close a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_CLOSER_LABEL =
    non_breaking(PANEL_CTRL_CFG.dig(:open, :label)).html_safe.freeze

  # Tooltip for button to close a collapsible panel.
  #
  # @type [String]
  #
  PANEL_CLOSER_TIP = PANEL_CTRL_CFG.dig(:open, :tooltip)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # toggle_button
  #
  # @param [String]              id         Element controlled by this button.
  # @param [String, nil]         label      Default: #PANEL_OPENER_LABEL.
  # @param [String, Symbol, nil] context    Default: 'for-panel'.
  # @param [Boolean, String]     open       Start with the element expanded.
  # @param [String, nil]         selector   Selector of the element controlled
  #                                           by this button (only used if
  #                                           panel.js RESTORE_PANEL_STATE is
  #                                           *true*).
  # @param [Hash] opt                       Passed to #button_tag.
  #
  # @raise [RuntimeError]             The controlled element was not specified.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/panel.js
  #
  def toggle_button(
    id:,
    label:    nil,
    context:  nil,
    open:     nil,
    selector: nil,
    **opt
  )
    css = '.toggle'
    opt[:'aria-controls'] = id.presence or raise 'no target id given'
    open = 'open' if open.is_a?(TrueClass)
    open = nil    unless open.is_a?(String)
    if context
      # noinspection RubyNilAnalysis
      context = "for-#{context}" unless context.start_with?('for-')
    elsif css_class_array(opt[:class]).none? { |c| c.start_with?('for-') }
      context = 'for-panel'
    end
    if selector.present?
      opt[:'data-selector'] = selector
      opt[:data] = opt[:data].except(:selector) if opt[:data].is_a?(Hash)
    end
    label       &&= non_breaking(label)
    label       ||= open ? PANEL_CLOSER_LABEL : PANEL_OPENER_LABEL
    opt[:title] ||= open ? PANEL_CLOSER_TIP   : PANEL_OPENER_TIP
    prepend_css!(opt, css, context, open)
    html_button(label, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
