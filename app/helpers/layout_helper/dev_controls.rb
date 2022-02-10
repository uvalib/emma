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
  include SessionDebugHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show developer-only controls.
  #
  def show_dev_controls?(...)
    (developer? || !application_deployed?) && allow_dev_controls?
  end

  # Indicate whether display of developer-only controls is not suppressed.
  #
  def allow_dev_controls?(...)
    !false?(session['app.dev_controls'])
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
    # noinspection RubyMismatchedReturnType
    config_lookup('dev_controls.label', **opt) || 'DEV'
  end

  # Generate developer-only controls.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def dev_controls(**opt)
    prepend_classes!(opt, 'control')
    controls = []
    controls << dev_hide_dev_controls(**opt)
    controls << dev_toggle_session_debug(**opt)
    controls << dev_toggle_controller_debug(**opt)
    safe_join(controls.compact)
  end

  # A control for turning off display of developer-only controls. # TODO: I18n
  #
  # For the sake of demos, where the presence of developer-only controls might
  # be confusing, this control redirects with "app.dev_controls=false".
  #
  # To restore developer-only controls, the URL parameter
  # "app.dev_controls=true" must be supplied manually.
  #
  # @param [Hash] opt                 Passed to #dev_toggle_debug.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dev_hide_dev_controls(**opt)
    param = :dev_controls
    label = 'Suppress'
    tip   = [
      'Click to stop showing these controls',
      %Q(Supply "&#{param}=true" to restore them.),
      nil,
      %Q(NOTE: DOES NOT AFFECT session['app.debug']),
      '(Toggle this off first to remove all dev-only enhancements.)'
    ].join("\n")
    link  = request_parameters.merge!(param => false)
    link_to(label, link, **opt.merge!(title: tip))
  end

  # A control for toggling application debug status.
  #
  # @param [Boolean, nil] state       Default: `#session_debug?`.
  # @param [Hash]         opt         Passed to #dev_toggle_debug.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dev_toggle_session_debug(state: nil, **opt)
    param = 'app.debug'
    dev_toggle_debug(ctrlr: nil, state: state, param: param, **opt)
  end

  # A control for toggling debugging features for a specific controller.
  #
  # @param [Symbol, nil]  ctrlr       Default: `params[:controller]`.
  # @param [Boolean, nil] state       Default: `#session_debug?(ctrlr)`.
  # @param [Hash]         opt         Passed to #dev_toggle_debug.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def dev_toggle_controller_debug(ctrlr: nil, state: nil, **opt)
    ctrlr ||= params[:controller]&.to_sym
    # noinspection RubyMismatchedArgumentType
    return unless ParamsConcern::SPECIAL_DEBUG_CONTROLLERS.include?(ctrlr)
    param = "app.#{ctrlr}.debug"
    dev_toggle_debug(ctrlr: ctrlr, state: state, param: param, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A control for toggling a debug status. # TODO: I18n
  #
  # @param [Symbol, String, nil] ctrlr
  # @param [Boolean, nil]        state  Default: `#session_debug?(ctrlr)`.
  # @param [Symbol, String, nil] param  URL debug parameter (default: :debug).
  # @param [Hash]                opt    Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dev_toggle_debug(ctrlr:, state:, param:, **opt)
    param = param&.to_sym || :debug
    state = session_debug?(ctrlr) if state.nil?
    label = ctrlr ? "#{ctrlr.to_s.titleize} debug" : 'Debug'
    label = "#{label} %s" % (state ? 'ON' : 'OFF')
    link  = request_parameters.merge!(param => !state)
    tip   = 'Click to turn %s' % (state ? 'off' : 'on')
    link_to(label, link, **opt.merge!(title: tip))
  end

end

__loading_end(__FILE__)
