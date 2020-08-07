# app/helpers/popup_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# PopupHelper
#
module PopupHelper

  def self.included(base)
    __included(base, '[PopupHelper]')
  end

  include Emma::Unicode
  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  POPUP_BUTTON_CLASS   = 'control'
  POPUP_PANEL_CLASS    = 'popup-panel'
  POPUP_CLOSER_CLASS   = 'closer'
  POPUP_CONTROLS_CLASS = 'popup-controls'
  POPUP_DEFERRED_CLASS = 'deferred'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a popup control and popup element.
  #
  # @param [Hash] opt                 Passed to 'popup-container' except for:
  #
  # @option opt [String]  :title      Tooltip for the visible control.
  # @option opt [Boolean] :hidden     If *true*, the panel is displayed
  #                                     initially.
  # @option opt [Hash]    :control    Options for the visible control.
  # @option opt [Hash]    :panel      Options for the popup panel element.
  # @option opt [Hash]    :closer     Options for the panel closer icon.
  # @option opt [Hash]    :close      Options for the panel close button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def popup_container(**opt)
    hidden = ('hidden' if !opt.key?(:hidden) || opt.delete(:hidden))

    # Visible popup toggle control.
    control_tip = opt.delete(:title)
    control_opt = prepend_css_classes(opt.delete(:control), POPUP_BUTTON_CLASS)
    control_opt[:tabindex]        ||= 0
    control_opt[:role]            ||= 'button'
    control_opt[:title]           ||= control_tip
    control_opt[:'aria-label']    ||= control_opt[:title]
    control_opt[:'aria-haspopup'] ||= 'dialog'
    text = control_opt.delete(:text).presence
    icon = control_opt.delete(:icon).presence
    append_css_classes!(control_opt, (text ? 'text' : 'icon'))
    control = html_span(**control_opt) { text || icon }

    # Popup panel closer button in the top-right of the panel "frame".
    closer_css = POPUP_CLOSER_CLASS
    closer_opt = prepend_css_classes(opt.delete(:closer), closer_css, 'icon')
    closer_opt[:tabindex]     ||= 0
    closer_opt[:role]         ||= 'button'
    closer_opt[:title]        ||= 'Close this popup' # TODO: I18n
    closer_opt[:'aria-label'] ||= closer_opt[:title]
    closer     = closer_opt.delete(:icon) || 'X' # TODO: I18n
    closer     = html_span(**closer_opt) { closer }

    # Popup panel contents supplied by the block.
    content = Array.wrap(yield)
    content = safe_join(content, "\n")

    # Controls at the bottom of the panel (close button).
    close_opt = prepend_css_classes(opt.delete(:close), closer_css, 'text')
    close_opt[:title]        ||= closer_opt[:title]
    close_opt[:'aria-label'] ||= close_opt[:title]
    close    = close_opt.delete(:label) || 'Close' # TODO: I18n
    close    = button_tag(close, close_opt)
    controls = html_div(class: POPUP_CONTROLS_CLASS) { close }

    # The popup panel element starts hidden initially.
    panel_css = [POPUP_PANEL_CLASS, hidden]
    panel_opt = prepend_css_classes(opt.delete(:panel), *panel_css)
    panel_opt[:role] ||= 'dialog'
    panel_opt[:'aria-modal'] = true unless panel_opt.key?(:'aria-modal')
    panel = html_div(**panel_opt) { closer << content << controls }

    # The hidden panel is a sibling of the popup button:
    opt = prepend_css_classes(opt, 'popup-container')
    html_span(opt) { control << panel }
  end

end

__loading_end(__FILE__)
