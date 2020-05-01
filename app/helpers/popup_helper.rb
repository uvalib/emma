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

  # Render a popup control and popup element.
  #
  # @param [Hash] opt                 Passed to 'popup-container' except for:
  #
  # @option opt [String]  :title      Tooltip for the visible control.
  # @option opt [Boolean] :hidden     If *true*, the panel is displayed
  #                                     initially.
  # @option opt [Hash]    :control    Options for the visible control.
  # @option opt [Hash]    :panel      Options for the popup panel element.
  # @option opt [Hash]    :closer     Options for the panel closer button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def popup_container(**opt)
    hidden = ('hidden' if !opt.key?(:hidden) || opt.delete(:hidden))

    # Visible popup toggle control.
    control_tip = opt.delete(:title)
    control_opt = {
      icon:            '',
      class:           'control',
      title:           control_tip,
      role:            'button',
      tabindex:        0,
      'aria-haspopup': 'dialog',
      'aria-label':    control_tip,
    }
    merge_html_options!(control_opt, opt.delete(:control))
    icon    = control_opt.delete(:icon)
    control = html_span(icon, **control_opt)

    # Popup panel closer button.
    closer_tip = 'Close this popup' # TODO: I18n
    closer_opt = {
      icon:         'X',
      class:        'closer',
      title:        closer_tip,
      role:         'button',
      tabindex:     0,
      'aria-label': closer_tip,
    }
    merge_html_options!(closer_opt, opt.delete(:closer))
    icon   = closer_opt.delete(:icon)
    closer = html_span(icon, **closer_opt)

    # Popup panel contents supplied by the block.
    content = Array.wrap(yield).map { |v| ERB::Util.h(v) }
    content = safe_join(content, "\n")

    # Popup panel element starts hidden initially.
    panel_opt = {
      class:        "popup #{hidden}",
      role:         'dialog',
      'aria-modal': true,
    }
    merge_html_options!(panel_opt, opt.delete(:panel))
    panel = html_div(**panel_opt) { closer << content }

    # The hidden panel is a sibling of the popup button:
    opt = prepend_css_classes(opt, 'popup-container')
    html_span(opt) { control << panel }
  end

end

__loading_end(__FILE__)
