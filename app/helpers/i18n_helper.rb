# app/helpers/i18n_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting I18n lookup.
#
# noinspection RubyNilAnalysis
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
  # @param [Hash]                opt          Passed to #i18n_interpolations
  #                                             except for:
  #
  # @option opt [Boolean] :plural
  # @option opt [Boolean] :capitalize
  #
  # @return [String]
  #
  def unit_of(controller = nil, **opt)
    controller ||= params[:controller]
    opt, i18n_opt = partition_options(opt, :plural, :capitalize)
    plural  = opt[:plural] || (i18n_opt[:count].to_i > 1)
    capital = opt[:capitalize]
    result  = i18n_interpolations(controller.to_s, i18n_opt)
    if capital && plural
      result[:Items]
    elsif capital
      result[:Item]
    elsif plural
      result[:items]
    else
      result[:item]
    end
  end

  # Find the best match from config/locales/en.yml for the given partial path,
  # first looking under "emma.#{controller}", then under "emma.generic".
  #
  # @param [String, Symbol, nil] controller   Default: `#params[:controller]`.
  # @param [Array]               partial_path I18n tree below *controller*.
  # @param [Hash]                opt          Passed to #i18n_interpolations
  #                                             except for:
  #
  # @option opt [String, Symbol, Boolean] :mode
  # @option opt [Boolean]                 :one
  # @option opt [Boolean]                 :many
  #
  # @return [String]
  # @return [nil]
  #
  def i18n_lookup(controller, *partial_path, **opt)
    controller ||= params[:controller]
    partial_path = partial_path.join('.')
    keys = [
      :"emma.#{controller}.#{partial_path}",
      :"emma.generic.#{partial_path}",
      :"emma.#{partial_path}",
    ]
    opt, i18n_opt = partition_options(opt, :mode, :one, :many)
    mode = opt[:mode]
    unless false?(mode)
      vals = %i[many one]
      mode = nil if mode == :auto
      mode = (mode.to_sym unless mode.nil? || true?(mode))
      vals.find { |v| mode = v if true?(opt[v]) } unless vals.include?(mode)
      mode ||=
        if (count = i18n_opt[:count].to_i) > 1
          :many
        elsif count == 1
          :one
        else
          (params[:action] == 'index') ? :many : :one
        end
      vals.find { |v| break mode = nil if (mode == v) && false?(opt[v]) }
      keys = keys.flat_map { |k| [:"#{k}.#{mode}", k] } if mode
    end
    key = keys.shift
    i18n_opt[:default] = [*keys, *i18n_opt[:default]].compact.uniq.push('')
    i18n_opt.merge!(i18n_interpolations(controller.to_s, i18n_opt))
    I18n.t(key, i18n_opt).presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The variations on the description of a model item managed by a controller.
  #
  # @param [String, Symbol] controller   Default: `#params[:controller]`.
  # @param [Hash]           opt          Passed to #i18n_lookup_raw except for:
  #
  # @option opt [Boolean] :brief      Default.
  # @option opt [Boolean] :long
  #
  # @return [Hash]
  #
  # == Implementation Notes
  # This method does not have an embedded fallback value -- it assumes that
  # some form of "emma.generic.unit" will be found if there is no definition
  # for the given controller.
  #
  def i18n_interpolations(controller, **opt)
    opt, i18n_opt = partition_options(opt, :long, :brief)
    mode = (true?(opt[:long]) || false?(opt[:brief])) ? :long : :brief
    i18n_opt[:default] = single = plural = nil
    [controller, 'generic'].each do |key|
      unit = I18n.t("emma.#{key}.unit", **i18n_opt)
      if unit.is_a?(String)
        single = unit
      elsif unit.is_a?(Hash)
        if unit[mode].is_a?(String)
          single = unit[mode]
        elsif unit[mode].is_a?(Hash)
          single = unit[mode][:one]
          plural = unit[mode][:many] || unit[mode][:other]
        end
      end
      break if single || plural
    end
    # noinspection RubyNilAnalysis
    {
      item:  (single ||= plural.singularize),
      items: (plural ||= single.pluralize),
      Item:  single.capitalize,
      Items: plural.capitalize
    }
  end

end

__loading_end(__FILE__)
