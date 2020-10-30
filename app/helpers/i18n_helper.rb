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
    base.send(:extend, self)
  end

  include Emma::Common
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The descriptions of a model managed by a controller.
  #
  # @param [String, Symbol, nil] controller   Default: `#params[:controller]`.
  # @param [Hash]                opt          Passed to #i18n_interpolations.
  #
  # @return [Hash]
  #
  def units_of(controller, **opt)
    controller ||= request_parameters[:controller]
    i18n_interpolations(controller: controller, **opt)
  end

  # The applicable description of a model managed by a controller.
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
  def unit_of(controller, **opt)
    opt, i18n_opt = partition_options(opt, :plural, :capitalize)
    plural  = opt.key?(:plural) ? opt[:plural] : (i18n_opt[:count].to_i > 1)
    capital = opt[:capitalize]
    result  = units_of(controller, **i18n_opt)
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

  # i18n_lookup_order
  #
  # @param [String, Symbol, nil] controller
  # @param [String, Symbol, nil] action
  #
  # args[0] controller
  # args[1] action
  #
  # @return [Array<Symbol>]
  #
  def i18n_lookup_order(controller = nil, action = nil)
    result = []
    result << "emma.#{controller}.#{action}" if controller && action
    result << "emma.#{controller}.generic"   if controller
    result << "emma.#{controller}"           if controller
    result << "emma.generic.#{action}"       if action
    result << 'emma.generic'
    result << 'emma'
    # noinspection RubyYardReturnMatch
    result.map(&:to_sym)
  end

  # Find the best match from config/locales for the given partial path, first
  # looking under "emma.#{controller}", then under "emma.generic".
  #
  # @param [String, Symbol, nil] controller
  # @param [String]              partial_path I18n tree below *controller*.
  # @param [Array<String>]       defaults     Prepended to I18n :default.
  # @param [Hash]                opt          Passed to #i18n_interpolations
  #                                             except for:
  #
  # @option opt [String, Symbol, Boolean] :mode
  # @option opt [Boolean]                 :one
  # @option opt [Boolean]                 :many
  #
  # @return [String]                          The specified value.
  # @return [nil]                             No non-empty value was found.
  #
  def i18n_lookup(controller, partial_path, *defaults, **opt)
    opt, i18n_opt = partition_options(opt, :mode, :one, :many, :default)
    partial_path = partial_path.join('.') if partial_path.is_a?(Array)
    keys =
      [partial_path, *defaults, *opt.delete(:default)].flat_map { |key|
        if key.to_s.start_with?('en.', 'emma.')
          key.to_sym
        elsif key.present?
          i18n_lookup_order(controller).map { |base| :"#{base}.#{key}" }
        end
      }.compact
    units = i18n_interpolations(controller: controller, **i18n_opt)
    mode  = opt.delete(:mode)
    unless false?(mode)
      vals = %i[many one]
      mode = nil if mode == :auto
      mode = (mode.to_sym unless mode.nil? || true?(mode))
      mode = vals.find { |v| true?(opt[v]) } unless vals.include?(mode)
      mode ||=
        case i18n_opt[:count].to_i
          when 0 then (request_parameters[:action] == 'index') ? :many : :one
          when 1 then :one
          else        :many
        end
      unless false?(opt[mode])
        keys =
          keys.flat_map do |k|
            k.to_s.end_with?(".#{mode}") ? k : [:"#{k}.#{mode}", k]
          end
      end
    end
    keys.uniq!
    keys.push('') unless keys.last.blank?
    I18n.t(keys.shift, **i18n_opt.merge(units, default: keys)).presence
  end

  # Generate a hash of the most relevant button information with the form:
  #
  #   {
  #     submit: {
  #       enabled: {
  #         label:   String,
  #         tooltip: String,
  #       },
  #       disabled: {
  #         label:   String,
  #         tooltip: String,
  #       },
  #     },
  #     ...
  #   }
  #
  # The result will have all of the items for the given controller/action
  # that contain and label and/or tooltip under them.
  #
  # @param [String, Symbol] controller
  # @param [String, Symbol] action
  #
  # @return [Hash{Symbol=>Hash{Symbol=>String,Hash}}]
  #
  def i18n_button_values(controller, action)
    item_keys    = %i[label tooltip]
    state_keys   = %i[enabled disabled]
    lookup_order = i18n_lookup_order(controller, action)
    I18n.t("emma.#{controller}.#{action}", default: {}).map { |button, values|
      next unless values.is_a?(Hash)
      entry = {}
      item_keys.each do |item|
        state_keys.each do |state|
          variants = %W(#{state}.#{item} #{item})
          keys =
            lookup_order.flat_map { |base_path|
              variants.map { |variant| "#{base_path}.#{button}.#{variant}" }
            }.uniq.map(&:to_sym) << ''
          next if (item_value = I18n.t(keys.shift, default: keys)).blank?
          entry[state] ||= {}
          entry[state][item] = item_value
          entry[item]  ||= item_value
        end
      end
      [button, entry]
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The variations on the description of a model item managed by a controller.
  #
  # @param [String, Symbol, nil] controller
  # @param [String, Symbol, nil] action
  # @param [Hash]                opt  Passed to I18n#translate except for:
  #
  # @option opt [Boolean] :brief      Default.
  # @option opt [Boolean] :long
  # @option opt [Integer] :count      If == 1, only single; if != 1, only
  #                                     plural; default: *nil*.
  # @option opt [Boolean] :plural     If *true*, only plural; if *false*, only
  #                                     single; default: *nil*.
  #
  # @return [Hash{Symbol=>String}]
  #
  # == Implementation Notes
  # This method does not have an embedded fallback value -- it assumes that
  # some form of "emma.generic.unit" will be found if there is no definition
  # for the given controller.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def i18n_interpolations(controller: nil, action: nil, **opt)
    opt, i18n_opt = partition_options(opt, :long, :brief, :count, :plural)
    i18n_opt[:default] = single = plural = no_single = no_plural = nil
    if opt.key?(:plural)
      no_plural = !opt[:plural]
      no_single = !no_plural
    elsif opt.key?(:count)
      no_plural = (opt[:count].to_i == 1)
      no_single = !no_plural
    end
    mode = (true?(opt[:long]) || false?(opt[:brief])) ? :long : :brief

    # Get the most specific definition available.
    i18n_lookup_order(controller, action).find do |base_path|
      unit = I18n.t("#{base_path}.unit", **i18n_opt)
      unit = unit[mode] if unit.is_a?(Hash)
      if unit.is_a?(String)
        single = unit
      elsif unit.is_a?(Hash)
        single = unit[:one]  || unit.values.first
        plural = unit[:many] || unit[:other]
        single || plural
      end
    end

    # Return with all interpolation values unless limitations were indicated.
    {}.tap do |result|
      unless no_single
        result[:item]  = single ||= plural.singularize
        result[:Item]  = single.capitalize
      end
      unless no_plural
        result[:items] = plural ||= single.pluralize
        result[:Items] = plural.capitalize
      end
    end
  end

end

__loading_end(__FILE__)
