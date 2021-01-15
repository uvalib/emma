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
    opt        = request_parameters.merge(opt)
    controller = opt[:controller].to_sym
    action     = opt[:action].to_sym
    id         = opt[:selected] || opt[:id]

    select  = (id == 'SELECT') && %i[new edit delete].include?(action)
    route   = select ? "#{action}_select" : action
    actions = config_lookup("#{route}.page_controls", controller: controller)
    actions &&= page_control_actions(controller, *actions)
    return if actions.blank?

    anchor   = "#{action}-page-controls"
    label_id = opt[:label_id] || css_randomize(anchor)

    skip_nav_prepend(controller => anchor)

    l_opt = { class: 'label', id: label_id }
    label = html_div(l_opt) { page_controls_label(**opt) }

    c_opt    = { class: 'controls', 'aria-labelledby': label_id, id: anchor }
    controls = html_div(c_opt) { page_controls(*actions, id: id) }

    html_div(class: 'page-controls') { label << controls }
  end

  # Generate a list of controller/action pairs that the current user is able to
  # perform.
  #
  # If an action is given by an array, the first element is interpreted as a
  # controller.  If not the controller for *model* is assumed.
  #
  # @param [Class,Symbol,String] model
  # @param [Array<Symbol,Array>] actions
  #
  # @return [Array<Array<(Symbol,Symbol)>>]   Controller/action pairs.
  # @return [nil]                             No authorized actions were found.
  #
  def page_control_actions(model, *actions)
    controller = nil
    actions.map { |action|
      next if action.blank?
      if action.is_a?(Array)
        ctrlr, action = action.map(&:to_sym)
        resource = ctrlr.to_s.camelize.safe_constantize
      else
        unless controller
          if model.is_a?(Class)
            controller = model.to_s.underscore
          else
            controller = model.to_sym
            model      = model.to_s.camelize.safe_constantize
          end
        end
        ctrlr, action, resource = [controller, action.to_sym, model]
      end
      [ctrlr, action] if can?(action, resource)
    }.compact.presence
  end

  # Generate controls specified by controller/action pairs generated by
  # #page_controls_actions.
  #
  # @param [Array<Array<(Symbol,Symbol)>>] pairs
  # @param [Hash]                          path_opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def page_controls(*pairs, **path_opt)
    html_opt = { class: 'control' }
    html_opt[:method] = path_opt.delete(:method) if path_opt.key?(:method)
    path_opt[:link_opt] = html_opt
    item_id = path_opt.delete(:id)
    select  = (item_id == 'SELECT')
    pairs.map { |path|
      opt = path_opt
      if item_id
        controller, action = path
        if %i[new edit delete].include?(action&.to_sym)
          if select
            path = [controller, "#{action}_select"]
          else
            opt = opt.merge(id: item_id, ids: [item_id])
          end
        end
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
    config_lookup('page_controls.label', **opt)
  end

end

__loading_end(__FILE__)
