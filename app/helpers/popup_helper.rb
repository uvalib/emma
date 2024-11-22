# app/helpers/popup_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display of popups.
#
module PopupHelper

  include Emma::Unicode

  include HtmlHelper
  include LinkHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  POPUP_TOGGLE_CLASS   = 'popup-toggle'
  POPUP_PANEL_CLASS    = 'popup-panel'
  POPUP_CLOSER_CLASS   = 'closer'
  POPUP_CONTROLS_CLASS = 'popup-controls'
  POPUP_DEFERRED_CLASS = 'deferred'
  POPUP_RESIZE_CLASS   = 'resizable'
  POPUP_HIDDEN_MARKER  = 'hidden'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a freestanding popup element.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #make_popup_panel.
  # @param [Proc]   blk               Passed to #make_popup_panel.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/shared/modal-base.js
  #
  def modal_popup(css: '.modal-popup', **opt, &blk)
    prepend_css!(opt, css)
    make_popup_panel(**opt, &blk)
  end

  # Render a popup control and associated popup element.
  #
  # @param [Hash, nil] control        Options for the visible toggle control.
  # @param [Hash, nil] panel          Options for the popup panel element.
  # @param [String]    css            Characteristic CSS class/selector.
  # @param [Hash]      opt            Passed to 'inline-popup' except for
  #                                     options passed to #make_popup_toggle,
  #                                     #make_popup_panel.
  # @param [Proc]      blk            Passed to #make_popup_panel.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Popup panel content.
  # @yieldreturn [String,Array<String>]
  #
  # @see file:app/assets/stylesheets/layouts/controls/_popup.scss
  #
  def inline_popup(control: nil, panel: nil, css: '.inline-popup', **opt, &blk)

    # Visible modal popup activation toggle control.
    t_opt = opt.extract!(*POPUP_TOGGLE_OPT)
    t_opt.reverse_merge!(control) if control.is_a?(Hash)
    popup_toggle = make_popup_toggle(**t_opt)

    # Initially-hidden modal popup panel.
    p_opt = opt.extract!(*POPUP_PANEL_OPT)
    p_opt.reverse_merge!(panel) if panel.is_a?(Hash)
    prepend_css!(p_opt, POPUP_PANEL_CLASS)
    popup_panel = make_popup_panel(**p_opt, &blk)

    # The hidden panel is a sibling of the toggle control:
    prepend_css!(opt, css)
    html_span(**opt) do
      popup_toggle << popup_panel
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create a modal popup activation toggle control.
  #
  # @param [Hash, String, nil] button
  # @param [String, nil]       text
  # @param [String, nil]       label
  # @param [Symbol, nil]       type     Specify :icon, :text, or :button.
  # @param [Hash]              opt      Passed to element method.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def make_popup_toggle(button: nil, text: nil, label: nil, type: nil, **opt)
    type                  ||= (:button if button) || (:text if text) || :icon
    opt[:tabindex]        ||= 0
    opt[:role]            ||= 'button'
    opt[:'aria-label']    ||= opt[:title]
    opt[:'aria-haspopup'] ||= 'dialog'
    opt[:'data-original-tabindex'] ||= 0
    prepend_css!(opt, POPUP_TOGGLE_CLASS, type)
    if button.is_a?(Hash)
      merge_html_options!(opt, button)
      label = opt.delete(:label) || label || text || config_term(:popup,:label)
      html_button(label, **opt)
    elsif button
      html_div(button, **opt)
    elsif text
      text ||= label || config_term(:popup, :click)
      html_span(text, **opt)
    else
      icon_button(**opt)
    end
  end

  # Render a popup control and popup element.
  #
  # @param [Boolean]   hidden         If *false*, panel is displayed initially.
  # @param [Boolean]   resize         If *true*, the panel is resizable.
  # @param [Boolean]   left_grab      If *true*, resize grab is on the left.
  # @param [Hash, nil] closer         Options for the panel closer icon.
  # @param [Hash, nil] close          Options for the panel close button.
  # @param [Hash]      opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Popup panel content
  # @yieldreturn [String,Array<String>]
  #
  def make_popup_panel(
    hidden:    true,
    resize:    false,
    left_grab: false,
    closer:    nil,
    close:     nil,
    controls:  nil,
    **opt,
    &blk
  )
    closer_css = POPUP_CLOSER_CLASS

    # Popup panel closer button in the top-right of the panel "frame".
    closer_opt = prepend_css(closer, closer_css, 'icon')
    closer_opt[:tabindex]     ||= 0
    closer_opt[:role]         ||= 'button'
    closer_opt[:title]        ||= config_term(:popup, :close, :tooltip)
    closer_opt[:'aria-label'] ||= closer_opt[:title]
    close_icon = closer_opt.delete(:icon) || config_term(:popup, :close, :icon)
    close_icon = html_span(**closer_opt) { symbol_icon(close_icon) }

    # Popup panel contents supplied by the block.
    panel_content = Array.wrap(blk&.call)
    panel_content = safe_join(panel_content, "\n")

    # Controls at the bottom of the panel (close button).
    controls_opt = { class: POPUP_CONTROLS_CLASS }
    if controls.is_a?(Hash)
      merge_html_options!(controls_opt, controls)
    elsif controls
      controls = Array.wrap(controls).compact_blank
      controls.map! do |control|
        if control.is_a?(Hash)
          tag = control[:tag]   || :button
          lbl = control[:label] || config_term(:popup, :control, :label)
          html_tag(tag, lbl, **control.except(:tag, :label))
        else
          ERB::Util.h(control)
        end
      end
    end
    controls = [] unless controls.is_a?(Array)
    if controls.none? { _1.include?(closer_css) }
      b_opt = prepend_css(close, closer_css, 'text')
      label = b_opt.delete(:label) || config_term(:popup, :close, :label)
      b_opt[:title]        ||= closer_opt[:title]
      b_opt[:'aria-label'] ||= b_opt[:title] if label.html_safe?
      controls << html_button(label, **b_opt)
    end
    panel_controls = html_div(controls, **controls_opt)

    # The popup panel element starts hidden initially.
    #prepend_css!(opt, POPUP_PANEL_CLASS)
    append_css!(opt, POPUP_RESIZE_CLASS)  if resize
    append_css!(opt, 'left-grab')         if left_grab
    append_css!(opt, POPUP_HIDDEN_MARKER) if hidden
    opt[:role] ||= 'dialog'
    opt[:'aria-modal'] = true unless opt.key?(:'aria-modal')
    html_div(**opt) do
      close_icon << panel_content << panel_controls
    end
  end

  # @private
  POPUP_TOGGLE_OPT = method_key_params(:make_popup_toggle).freeze

  # @private
  POPUP_PANEL_OPT = method_key_params(:make_popup_panel).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
