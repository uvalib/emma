# app/helpers/layout_helper/dev_controls.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Control bar panel with developer-only affordances.
#
module LayoutHelper::DevControls

  include LayoutHelper::Common
  include ConfigurationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show developer-only controls.
  #
  def show_dev_controls?(*)
    developer? || !application_deployed?
  end

  # Render a container with developer-only controls.
  #
  # @param [Hash] opt
  #
  # @option opt [String, Symbol] :controller    Default: `params[:controller]`.
  # @option opt [String, Symbol] :action        Default: `params[:action]`.
  # @option opt [String]         :label_id
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       If no dev_controls configured.
  #
  def render_dev_controls(**opt)
    css_selector = '.dev-controls'

    anchor = 'dev-controls'
    l_id   = opt.delete(:label_id) || css_randomize(anchor)
    l_opt  = { class: 'label', id: l_id }
    c_opt  = { class: 'controls', 'aria-labelledby': l_id, id: anchor }

    label    = html_div(l_opt) { dev_controls_label(**opt) }
    controls = html_div(c_opt) { dev_controls(**opt) }

    html_div(class: css_classes(css_selector)) do
      label << controls
    end
  end

  # dev_controls_label
  #
  # @param [Hash] opt                 Passed to #config_lookup.
  #
  # @return [String]
  #
  def dev_controls_label(**opt)
    config_lookup('dev_controls.label', **opt) || 'DEV'
  end

  # Generate developer-only controls.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dev_controls(**opt)
    prepend_classes!(opt, 'control')
    controls = []
    controls << dev_toggle_debug(**opt)
    safe_join(controls)
  end

  # A control for toggling the #session_debug? status.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dev_toggle_debug(**opt)
    state = session_debug?
    label = 'Debug %s' % (state ? 'ON' : 'OFF')
    link  = request_parameters.merge!(debug: !state)
    tip   = 'Click to turn %s' % (state ? 'off' : 'on')
    link_to(label, link, **opt.merge!(title: tip))
  end

end

__loading_end(__FILE__)
