# app/helpers/i18n_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting I18n lookup.
#
module I18nHelper

  def self.included(base)
    __included(base, '[I18nHelper]')
  end

  include GenericHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The description of a model managed by a controller.
  #
  # @param [String, Symbol, nil] controller   Default: `#params[:controller]`.
  # @param [Hash]                opt
  #
  # @option opt [Boolean] :brief      Default.
  # @option opt [Boolean] :long
  # @option opt [Boolean] :plural
  # @option opt [Boolean] :capitalize
  #
  # @return [String]
  #
  def unit_of(controller = nil, **opt)
    controller ||= params[:controller]
    if opt.present?
      i18n_opt, opt = extract_options(opt, :long, :brief, :plural, :capitalize)
      mode   = (true?(opt[:long]) || false?(opt[:brief])) ? 'long' : 'brief'
      count  = i18n_opt[:count]&.to_i
      plural = count && (count != 1) || opt[:plural]
      store  = false
    elsif (@unit_of ||= {})[controller].blank?
      i18n_opt = {}
      mode   = 'brief'
      plural = false
      store  = true
    else
      return @unit_of[controller]
    end
    number  = plural ? 'many' : 'one'
    default = i18n_opt[:default] || 'unit'
    i18n_opt[:default] = nil
    result   = I18n.t("emma.#{controller}.unit.#{mode}.#{number}", i18n_opt)
    result ||= I18n.t("emma.generic.unit.#{mode}.#{number}", i18n_opt)
    plural &&= result.blank?
    result ||= I18n.t("emma.#{controller}.unit.#{mode}", i18n_opt)
    result ||= I18n.t("emma.generic.unit.#{mode}", i18n_opt)
    result ||= default
    result   = result.pluralize  if plural
    result   = result.capitalize if opt[:capitalize]
    store ? (@unit_of[controller] = result) : result
  end

  # page_controls_label
  #
  # @param [String, Symbol, nil] controller   Default: `#params[:controller]`.
  # @param [Hash]                opt
  #
  # @option opt [String, Symbol] :mode        Either 'one' or 'many'.
  # @option opt [Boolean]        :one
  # @option opt [Boolean]        :many
  #
  # @return [String]
  #
  def page_controls_label(controller = nil, **opt)
    controller ||= params[:controller]
    mode = opt[:mode]&.to_sym
    mode = :many if true?(opt[:many]) || false?(opt[:one])
    mode = :one  if true?(opt[:one])  || false?(opt[:many])
    mode ||= (params[:action] == 'index') ? :many : :one
    I18n.t("emma.#{controller}.page_controls.label.#{mode}", default: nil) ||
      I18n.t(
        "emma.generic.page_controls.label.#{mode}",
        item:    (unit = unit_of(controller)),
        items:   unit.pluralize,
        Item:    unit.capitalize,
        Items:   unit.capitalize.pluralize,
        default: [
          :"emma.#{controller}.page_controls.label",
          :'emma.generic.page_controls.label',
          'Controls'
        ]
      )
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # action_label
  #
  # @param [String, Symbol, nil] action       Default: `#params[:action]`.
  # @param [String, Symbol, nil] controller   Default: `#params[:controller]`.
  # @param [Hash]                opt          Passed to `I18n#t`.
  #
  # @return [String]
  #
  def action_label(action = nil, controller = nil, **opt)
    action_lookup(:label, action, controller, opt).presence || 'Action'
  end

  # action_tooltip
  #
  # @param [String, Symbol, nil] action       Default: `#params[:action]`.
  # @param [String, Symbol, nil] controller   Default: `#params[:controller]`.
  # @param [Hash]                opt          Passed to `I18n#t`.
  #
  # @return [String]
  #
  def action_tooltip(action = nil, controller = nil, **opt)
    action_lookup(:tooltip, action, controller, opt)
  end

  # action_lookup
  #
  # @param [String, Symbol]      value        Value to lookup.
  # @param [String, Symbol, nil] action       Default: `#params[:action]`.
  # @param [String, Symbol, nil] controller   Default: `#params[:controller]`.
  # @param [Hash]                opt          Passed to `I18n#t`.
  #
  # @return [String]
  #
  def action_lookup(value, action = nil, controller = nil, **opt)
    controller ||= params[:controller]
    action     ||= params[:action]
    I18n.t(
      "emma.#{controller}.#{action}.#{value}",
      opt.reverse_merge(default: nil)
    ) ||
      I18n.t(
        "emma.generic.#{action}.#{value}",
        opt.reverse_merge(item: unit_of(controller), default: '')
      )
  end

end

__loading_end(__FILE__)
