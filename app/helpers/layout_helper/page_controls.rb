# app/helpers/layout_helper/page_controls.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Control bar which holds action controls appropriate for the current page and
# the current user.
#
module LayoutHelper::PageControls

  include LayoutHelper::Common

  include ConfigurationHelper
  include IdentityHelper
  include LinkHelper
  include ParamsHelper

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Emma::Common::ObjectMethods
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show page controls.
  #
  # @param [Hash, nil] p              Default: `#request_parameters`.
  #
  def show_page_controls?(p = nil)
    p ||= request_parameters
    !p[:controller].to_s.include?('devise')
  end

  # Render the appropriate partial to insert page controls if they are defined
  # for the current controller/action.
  #
  # @param [String] css               CSS class/selector for outer container.
  # @param [Hash]   opt
  #
  # @option opt [String, Symbol] :controller    Default: `params[:controller]`.
  # @option opt [String, Symbol] :action        Default: `params[:action]`.
  # @option opt [String]         :label_id
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       If no page_controls configured.
  #
  def render_page_controls(css: '.page-controls', **opt)
    opt     = request_parameters.merge(opt)
    id      = opt[:selected] || opt[:id]
    ctrlr   = opt[:controller].to_sym
    action  = opt[:action].to_sym
    ca_opt  = { controller: ctrlr, action: action }
    actions = page_control_actions(**ca_opt).presence or return
    anchor  = "#{action}-page-controls"
    lbl_id  = opt.delete(:label_id) || css_randomize(anchor)

    skip_nav_prepend(ctrlr => anchor)

    label =
      html_div(class: 'label', id: lbl_id) do
        page_controls_label(**opt)
      end

    controls =
      html_div(class: 'controls', id: anchor, 'aria-labelledby': lbl_id) do
        page_controls(*actions, id: id, **ca_opt)
      end

    html_div(class: css_classes(css)) do
      label << controls
    end
  end

  # Generate a list of controller/action pairs that the current user is able to
  # perform.
  #
  # If an action is given by an array, the first element is interpreted as a
  # controller.  If not the controller for *model* is assumed.
  #
  # @param [Symbol] controller
  # @param [Symbol] action
  #
  # @return [Array<Array<(Symbol,Symbol)>>]   Controller/action pairs.
  # @return [nil]                             No authorized actions were found.
  #
  def page_control_actions(controller:, action:)
    cfg_opt = { controller: controller, action: action, mode: false }
    actions = config_lookup('page_controls.actions', **cfg_opt)
    return if actions.blank?
    model   = model_class(controller)
    user    = (@user || current_user)
    subject = (user if model == User)
    log     = (->(m) { Log.debug("#{__method__}: #{m}") } if Log.debug?)
    actions.map { |entry|
      next if entry.blank?
      if entry.is_a?(Array)
        ctrlr, action = entry.map(&:to_sym)
        subj   = subject || model_class(ctrlr)
      else
        ctrlr  = controller
        action = entry.to_sym
        subj   = subject || model
      end
      next log&.('no action')                        unless action.present?
      next log&.("#{action} not permitted for user") unless can?(action, subj)
      role    = config_lookup('role', controller: ctrlr, action: action)
      allowed = user_has_role?(role, user)
      next log&.("#{action} requires #{role} role")  unless allowed
      [ctrlr, action]
    }.compact
  end

  # Generate controls specified by controller/action pairs generated by
  # #page_controls_actions.
  #
  # Any control which would lead back to the current page is disabled and
  # marked to indicate that the selected action has already been chosen.
  #
  # @param [Array<Array<(Symbol,Symbol)>>] pairs
  # @param [Symbol, String, nil]           controller   Current controller.
  # @param [Symbol, String, nil]           action       Current action.
  # @param [Hash]                          path_opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def page_controls(*pairs, controller: nil, action: nil, **path_opt)
    html_opt = { class: 'control', method: path_opt.delete(:method) }.compact
    item_id  = path_opt.delete(:id)
    link_opt = path_opt.delete(:link_opt)&.dup || {}
    append_css!(html_opt, link_opt[:class])
    path_opt[:link_opt] = link_opt.merge!(html_opt)
    ctrlr  = controller&.to_sym
    action = action&.to_sym
    base   = action&.to_s&.delete_suffix('_select')&.to_sym
    if (select = (action != base))
      action &&= base                if item_id
    else
      action &&= :"#{action}_select" if item_id == 'SELECT'
    end
    pairs.map { |path|
      ctr, act = path
      state = []
      if act && action && (ctr == ctrlr)
        base_act = act.to_s.delete_suffix('_select').to_sym
        act      = :"#{act}_select" if select && !act.end_with?('_select')
        state << 'current'  if base   == base_act
        state << 'disabled' if action == act
      end
      opt = path_opt.merge(controller: ctr, action: act)
      opt[:link_opt] = append_css(link_opt, *state)
      page_control(**opt)
    }.compact.join("\n").html_safe
  end

  # This is a kludge specifically for getting the controls on "/home/dashboard"
  # to look right.  Although the :edit control is going to "/account/edit/:id",
  # we want the label/tooltip configuration for "/user/registrations/edit".
  # (The generic "/account/edit" refers to changing "an account" rather than
  # "your account").
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def page_control(**opt)
    label = tip = nil
    ctr, act, id = opt.values_at(:controller, :action, :id)
    if (ctr == :account) && (act == :edit) && (!id || (id == current_user&.id))
      cfg_opt = { ctrlr: 'user/registrations', action: act }
      label   = config_lookup('label',   **cfg_opt)
      tip     = config_lookup('tooltip', **cfg_opt)
    end
    link_opt = opt[:link_opt] ||= {}
    link_opt[:role]  ||= 'button'
    link_opt[:title] ||= tip  if tip
    # noinspection RubyMismatchedReturnType, RubyMismatchedArgumentType
    link_to_action(label, **opt)
  end

  # page_controls_label
  #
  # @param [Hash] opt                 Passed to #config_lookup.
  #
  # @return [String]
  #
  def page_controls_label(**opt)
    opt      = request_parameters.merge(opt)
    selected = opt.delete(:selected)
    id       = opt.delete(:id)
    if opt.slice(:mode, :one, :many).blank?
      if selected
        opt[:one] = true
      elsif (id == 'SELECT') || opt[:action]&.end_with?('_select')
        opt[:many] = true
      end
    end
    config_lookup('page_controls.label', **opt) || 'Controls' # TODO: I18n
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # model_class
  #
  # @param [Symbol, String, Class, *] ctrlr
  #
  # @return [Class]
  # @return [nil]
  #
  def model_class(ctrlr)
    if ctrlr.is_a?(String) || ctrlr.is_a?(Symbol)
      case ctrlr.to_sym
        when :admin          then return # without warning
        when :upload         then return Upload
        when :account, :home then return User
        else                      return User if ctrlr.start_with?('user/')
      end
    end
    result = to_class(ctrlr)
    if result.is_a?(Class) && result.ancestors.include?(Model)
      result
    else
      Log.warn { "#{__method__}: unexpected: #{ctrlr.inspect}" }
    end
  end

end

__loading_end(__FILE__)
