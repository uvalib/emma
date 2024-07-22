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
  include IdentityHelper
  include ParamsHelper
  include SessionDebugHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show developer-only controls.
  #
  def show_dev_controls?(...)
    (developer? || not_deployed?) && allow_dev_controls?
  end

  # Indicate whether display of developer-only controls is not suppressed.
  #
  def allow_dev_controls?(...)
    !false?(session['app.dev_controls'])
  end

  # Render a container with developer-only controls.
  #
  # @param [Hash]   outer             HTML options for outer div container.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to label and control elements.
  #
  # @option opt [Hash]           :params        Default: `#request_parameters`
  # @option opt [String, Symbol] :controller    Optional override.
  # @option opt [String, Symbol] :action        Optional override.
  # @option opt [String]         :label_id
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       If no dev_controls configured.
  #
  def render_dev_controls(outer: nil, css: '.dev-controls', **opt)
    ctrlr_action   = opt.extract!(:controller, :action).compact_blank!
    opt[:params] ||= request_parameters
    opt[:params]   = opt[:params].merge(ctrlr_action) if ctrlr_action.present?

    anchor    = 'dev-controls'
    l_id      = opt.delete(:label_id) || css_randomize(anchor)
    l_opt     = { class: 'label', id: l_id }
    c_opt     = { class: 'controls', id: anchor, 'aria-labelledby': l_id }

    label     = html_div(**l_opt) { dev_controls_label(**opt) }
    controls  = html_div(**c_opt) { dev_controls(**opt) }

    outer_opt = prepend_css(outer, css)
    html_div(**outer_opt) do
      label << controls
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # dev_controls_label
  #
  # @param [Hash] opt                 Passed to #config_lookup except:
  #
  # @option opt [Hash] :params
  #
  # @return [String]
  #
  def dev_controls_label(**opt)
    prm = opt.delete(:params)&.slice(:controller, :action)
    opt.reverse_merge!(prm) if prm.present?
    config_lookup('dev_controls.label', **opt) || 'DEV'
  end

  # Generate developer-only controls.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dev_controls(css: '.control', **opt)
    prepend_css!(opt, css)
    controls = []
    controls << dev_hide_dev_controls(**opt)
    controls << dev_toggle_session_debug(**opt)
    controls << dev_toggle_controller_debug(**opt)
    safe_join(controls.compact)
  end

  # A control for turning off display of developer-only controls.
  #
  # For the sake of demos, where the presence of developer-only controls might
  # be confusing, this control redirects with "app.dev_controls=false".
  #
  # To restore developer-only controls, the URL parameter
  # "app.dev_controls=true" must be supplied manually.
  #
  # @param [Hash] opt                 Passed to #make_link except for:
  #
  # @option opt [Hash] :params        Required to generate the link path.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dev_hide_dev_controls(**opt)
    param = :dev_controls
    text  = config_term_section(:dev, :hide_dev_controls, param: param)
    label = text[:label]
    tip   = Array.wrap(text[:tooltip]).join("\n")
    link  = opt.delete(:params).merge(param => false)
    make_link(link, label, **opt, title: tip)
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
  # @param [Symbol, nil]  ctrlr       Default: `opt[:params][:controller]`.
  # @param [Boolean, nil] state       Default: `#session_debug?(ctrlr)`.
  # @param [Hash]         opt         Passed to #dev_toggle_debug.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def dev_toggle_controller_debug(ctrlr: nil, state: nil, **opt)
    ctrlr ||= opt.dig(:params, :controller)&.to_sym
    return unless ParamsConcern::SPECIAL_DEBUG_CONTROLLERS.include?(ctrlr)
    param = "app.#{ctrlr}.debug"
    dev_toggle_debug(ctrlr: ctrlr, state: state, param: param, **opt)
  end

  # A control for toggling a debug status.
  #
  # @param [Symbol, String, nil] ctrlr
  # @param [Boolean, nil]        state  Default: `#session_debug?(ctrlr)`.
  # @param [Symbol, String, nil] param  URL debug parameter (default: :debug).
  # @param [Hash]                opt    Passed to #make_link except for:
  #
  # @option opt [Hash] :params          Required to generate the link path.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dev_toggle_debug(ctrlr:, state:, param:, **opt)
    param = param&.to_sym || :debug
    state = session_debug?(ctrlr) if state.nil?
    t_opt = {}
    t_opt[:ctrlr] = ctrlr.to_s.titleize if ctrlr

    t_opt[:state] = config_term(state ? :_on : :_off).upcase
    label = ctrlr ? :ctrlr_label : :label
    label = config_term(:dev, :toggle_debug, label, **t_opt)

    t_opt[:state] = config_term(state ? :_off : :_on)
    tip   = config_term(:dev, :toggle_debug, :tooltip, **t_opt)

    link  = opt.delete(:params).merge(param => !state)
    make_link(link, label, **opt, title: tip)
  end

end

__loading_end(__FILE__)
