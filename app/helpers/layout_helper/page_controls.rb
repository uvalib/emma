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
  include LinkHelper

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
  # @param [Hash] opt
  #
  # @option opt [String, Symbol] :controller    Default: `params[:controller]`.
  # @option opt [String, Symbol] :action        Default: `params[:action]`.
  # @option opt [String]         :label_id
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       If no page_controls configured.
  #
  def render_page_controls(**opt)
    css_selector = '.page-controls'
    opt          = request_parameters.merge(opt)
    controller   = opt[:controller].to_sym
    action       = opt[:action].to_sym
    id           = opt[:selected] || opt[:id]

    select   = (id == 'SELECT') && %i[new edit delete].include?(action)
    pca_opt  = { controller: controller, action: action }
    pca_opt[:action] = :"#{action}_select" if select
    actions  = page_control_actions(**pca_opt).presence or return

    anchor   = "#{action}-page-controls"
    label_id = opt[:label_id] || css_randomize(anchor)

    l_opt    = { class: 'label', id: label_id }
    label    = html_div(l_opt) { page_controls_label(**opt) }

    ctl_opt  = { class: 'controls', 'aria-labelledby': label_id, id: anchor }
    pc_opt   = { controller: controller, action: action, id: id }
    controls = html_div(ctl_opt) { page_controls(*actions, **pc_opt) }

    skip_nav_prepend(controller => anchor)

    html_div(class: css_classes(css_selector)) do
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
    # noinspection RubyMismatchedReturnType
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
      next unless action.present? && can?(action, subj)
      role = config_lookup('role', controller: ctrlr, action: action)
      next unless role.blank? || has_role?(role, user)
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
    append_classes!(html_opt, link_opt[:class])
    path_opt[:link_opt] = link_opt.merge!(html_opt)
    controller = controller&.to_sym
    action     = action&.to_sym
    pairs.map { |path|
      opt = path_opt.dup
      p_ctrlr, p_action = path
      if p_action
        if item_id && %i[new edit delete].include?(p_action.to_sym)
          if item_id != 'SELECT'
            opt[:id] = item_id
          elsif !p_action.end_with?('_select')
            path = [p_ctrlr, (p_action = :"#{p_action}_select")]
          end
        end
        current =
          if action && (controller == p_ctrlr)
            # noinspection RubyNilAnalysis
            a_sel = action.end_with?('_select')
            p_sel = p_action.end_with?('_select')
            case
              when p_sel && !a_sel then p_action == :"#{action}_select"
              when a_sel && !p_sel then action == :"#{p_action}_select"
              else                      action == p_action
            end
          end
        opt[:link_opt] = append_classes(link_opt, 'disabled') if current
        path = [p_ctrlr, :new] if p_action.to_s == 'new_select'
      end
      link_to_action(nil, path: path, **opt)
    }.compact.join("\n").html_safe
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
    # noinspection RubyMismatchedReturnType
    config_lookup('page_controls.label', **opt) || 'Controls'
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # model_class
  #
  # @param [Symbol, String, ApplicationController, *] ctrlr
  #
  # @return [Class]
  # @return [nil]
  #
  def model_class(ctrlr)
    if ctrlr.is_a?(String) || ctrlr.is_a?(Symbol)
      case ctrlr.to_sym
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
