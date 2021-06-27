# app/helpers/configuration_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting "/config/locales" configuration lookup.
#
module ConfigurationHelper

  # @private
  def self.included(base)

    __included(base, 'ConfigurationHelper')

    base.send(:extend, self)

  end

  include Emma::Common
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  CONFIG_ITEM_KEYS  = %i[label tooltip].freeze
  CONFIG_STATE_KEYS = %i[enabled disabled].freeze

  # Fall-back fatal configuration message. # TODO: I18n
  #
  # @type [String]
  #
  CONFIG_FAIL = 'Fatal configuration error'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Determine the path through the configuration hierarchy for the given
  # controller/action pair.
  #
  # For ctrlr == 'user/registrations' and action == 'edit' this yields
  # %i[user registrations edit].
  #
  # @param [String, Symbol, nil] controller
  # @param [String, Symbol, nil] action
  #
  # @return [Array<Symbol>]
  #
  def config_path(controller = nil, action = nil)
    result = controller.to_s.underscore.split('/') << action
    result.compact_blank.map(&:to_sym)
  end

  # controller_configuration
  #
  # @param [String, Symbol, nil] controller
  # @param [String, Symbol, nil] action
  #
  # @return [Hash{Symbol=>*}]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def controller_configuration(controller = nil, action = nil)
    result = ApplicationHelper::CONTROLLER_CONFIGURATION
    return result unless controller
    path = config_path(controller, action)
    result.dig(*path) || {}
  end

  # config_lookup_order
  #
  # @param [String, Symbol, nil] controller
  # @param [String, Symbol, nil] action
  #
  # @return [Array<Array<Symbol>>]
  #
  def config_lookup_order(controller = nil, action = nil)
    ctr, sub, act = path = config_path(controller, action)
    sub, act = [nil, sub] if action && (path.size == 2)
    result = []
    result << [ctr, sub, act]      if ctr && sub && act
    result << [ctr, sub, :generic] if ctr && sub
    result << [ctr, sub]           if ctr && sub
    result << [ctr, act]           if ctr && act
    result << [ctr, :generic]      if ctr
    result << [ctr]                if ctr
    result << [:generic, act]      if act
    result << [:generic]
  end

  # Find the best match from config/locales for the given partial path, first
  # looking under "en.emma.(controller)", then under 'en.emma.generic'.
  #
  # @param [String, Array] path       Partial I18n path.
  # @param [*]             default    Returned on failure.
  # @param [Boolean, *]    fatal      If *true* an exception is raised instead.
  # @param [Hash]          opt        Passed to #config_interpolations except:
  #
  # @option opt [String, Symbol]          :controller
  # @option opt [String, Symbol]          :action
  # @option opt [String, Symbol, Boolean] :mode
  # @option opt [Boolean]                 :one
  # @option opt [Boolean]                 :many
  #
  # @raise [RuntimeError]             If *fatal* and configuration not found.
  #
  # @return [*]                       The specified value or *default*.
  #
  # @example Simple path - [:button, :label]
  # Returns the most specific configuration match from the list:
  #   * "en.emma.(controller).(action).button.label"
  #   * "en.emma.(controller).generic.button.label"
  #   * "en.emma.(controller).button.label"
  #   * "en.emma.generic.(action).button.label"
  #   * "en.emma.generic.button.label"
  #
  # @example Branching path - [[:button1, :button2], :label]
  # Returns the most specific configuration match from the list:
  #   * "en.emma.(controller).(action).button1.label"
  #   * "en.emma.(controller).(action).button2.label"
  #   * "en.emma.(controller).generic.button1.label"
  #   * "en.emma.(controller).generic.button2.label"
  #   * "en.emma.(controller).button1.label"
  #   * "en.emma.(controller).button2.label"
  #   * "en.emma.generic.(action).button1.label"
  #   * "en.emma.generic.(action).button2.label"
  #   * "en.emma.generic.button1.label"
  #   * "en.emma.generic.button2.label"
  #
  def config_lookup(
    *path,
    controller: nil,
    action:     nil,
    default:    nil,
    fatal:      false,
    **opt
  )
    opt, i_opt = partition_hash(opt, :mode, :one, :many)
    vals = %i[many one]
    mode = opt[:mode]
    if false?(mode) #|| vals.include?(item)
      mode = nil
    else
      mode = nil if mode == :auto
      mode = (mode.to_sym unless mode.nil? || true?(mode))
      mode = vals.find { |v| true?(opt[v]) } unless vals.include?(mode)
      mode ||=
        case i_opt[:count].to_i
          when 0 then (request_parameters[:action] == 'index') ? :many : :one
          when 1 then :one
          else        :many
        end
      mode = nil if false?(opt[mode])
    end
    i_opt[:controller] ||= controller

    lookup_order = config_lookup_order(controller, action)
    lookup_order.map! { |path_parts| path_parts.join('.') }
    config_flatten_order(lookup_order, *path).find do |full_path|
      item  = full_path.pop
      entry = controller_configuration.dig(*full_path)
      next unless entry.is_a?(Hash) && entry.key?(item)
      entry = entry[item]
      entry = entry[mode] if mode && entry.is_a?(Hash) && entry.key?(mode)
      return apply_config_interpolations(entry, **i_opt)
    end
    fatal ? raise(CONFIG_FAIL) : default
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
  def config_button_values(controller, action)
    lookup_order  = config_lookup_order(controller, action)
    action_config = controller_configuration(controller, action)
    buttons       = action_config.select { |_, v| v.is_a?(Hash) }.keys
    buttons.map { |button|
      config = {}
      CONFIG_ITEM_KEYS.each do |key|
        CONFIG_STATE_KEYS.each do |state|
          lookup_order.find do |base_path|
            entry = controller_configuration.dig(*base_path, button) || {}
            if entry[state].is_a?(Hash) && entry[state].key?(key)
              value = entry[state][key]
            elsif entry.key?(key)
              value = entry[key]
            else
              next
            end
            config[state]     ||= {}
            config[state][key]  = value unless config[state].key?(key)
            config[key]         = value unless config.key?(key)
          end
        end
      end
      [button, config]
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate a set of explicit paths through the configuration hierarchy based
  # on the path element(s) given.
  #
  # @param [String, Symbol, Array] path   Partial I18n path.
  # @param [Integer]               depth  Recursion depth.
  #
  # @return [Array<Array<Symbol>>]
  #
  def config_flatten_order(*path, depth: 0)
    result = []
    path.map! { |p| p.is_a?(Array) ? p.compact_blank : p }.compact_blank!
    while path.present? && !path.first.is_a?(Array)
      part = path.shift
      unless part.is_a?(Symbol) || (part.is_a?(String) && part.include?('.'))
        part = part.to_s.to_sym
      end
      result << part
    end
    if (branches = path.shift)
      down_one = depth + 1
      branches = config_flatten_order(*branches, depth: down_one).flatten(1)
      if path.present?
        remainder = config_flatten_order(*path, depth: down_one).flatten(1)
        branches  = branches.product(remainder)
      end
      result = branches.map { |branch| [*result, *branch].flatten }
    else
      result = [result]
    end
    if depth.zero?
      result.uniq!
      result.map! do |entry|
        entry.flat_map do |item|
          if item.is_a?(String)
            item.split('.').compact_blank.map(&:to_sym)
          else
            item
          end
        end
      end
    end
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # apply_config_interpolations
  #
  # @param [Hash, Array, String, Integer, Boolean, nil] item
  # @param [Hash] opt
  #
  # @return [Hash, Array, String, Integer, Boolean, nil]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def apply_config_interpolations(item, **opt)
    opt[:units] ||= config_interpolations(**opt)
    if item.is_a?(Hash)
      item.transform_values { |v| send(__method__, v, **opt) }
    elsif item.is_a?(Array)
      item.map { |v| send(__method__, v, **opt) }
    elsif item.is_a?(String) && item.include?('%{')
      item.gsub(/%{([^}]+)}/) do |s|
        name = $1&.to_sym
        name && opt[:units][name] || s
      end
    else
      item
    end
  end

  # The variations on the description of a model item managed by a controller.
  #
  # @param [String, Symbol, nil] controller
  # @param [String, Symbol, nil] action
  # @param [Boolean]             brief      Default: *true*.
  # @param [Boolean]             long       Default: *false*.
  # @param [Symbol, nil]         mode       To specify either :brief or :long.
  # @param [Integer, nil]        count      If == 1, only single; if != 1, only
  #                                           plural.
  # @param [Boolean, nil]        plural     If *true*, only plural; if *false*,
  #                                           only single.
  #
  # @return [Hash{Symbol=>String}]
  #
  # == Implementation Notes
  # This method does not have an embedded fallback value -- it assumes that
  # some form of 'emma.generic.unit' will be found if there is no definition
  # for the given controller.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def config_interpolations(
    controller: nil,
    action:     nil,
    brief:      true,
    long:       false,
    mode:       nil,
    count:      nil,
    plural:     nil,
    **
  )
    no_plural = no_single = nil
    if !plural.nil?
      no_plural = false?(plural)
      no_single = !no_plural
    elsif !count.nil?
      no_plural = (count.to_i == 1)
      no_single = !no_plural
    end
    mode ||= (true?(long) || false?(brief)) ? :long : :brief

    # Get the most specific definition available.
    single = plural = nil
    config_lookup_order(controller, action).find do |base_path|
      unit = controller_configuration.dig(*base_path, :unit)
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
    result = {
      item:  (single ||= plural.singularize unless no_single),
      Item:  (single.capitalize             unless no_single),
      items: (plural ||= single.pluralize   unless no_plural),
      Items: (plural.capitalize             unless no_plural),
    }
    # noinspection RubyYardReturnMatch
    result.compact
  end

end

__loading_end(__FILE__)
