# app/helpers/configuration_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting "/config/locales" configuration lookup.
#
module ConfigurationHelper

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
    entry =
      config_lookup_paths(controller, action, *path).find do |full_path|
        item = full_path.pop
        cfg  = controller_configuration.dig(*full_path)
        break cfg[item] if cfg.is_a?(Hash) && cfg.key?(item)
      end
    raise(CONFIG_FAIL) if entry.nil? && fatal
    return default     if entry.nil?

    opt, i_opt = partition_hash(opt, :mode, :one, :many)
    i_opt[:controller] ||= controller

    # Use count-specific definitions if present.
    if entry.is_a?(Hash) && !false?((mode = opt[:mode]))
      vals = %i[many one]
      mode = mode.to_sym unless mode.nil? || true?(mode)
      mode = nil if mode == :auto
      mode = vals.find { |v| true?(opt[v]) } unless vals.include?(mode)
      mode ||=
        case i_opt[:count].to_i
          when 0 then (request_parameters[:action] == 'index') ? :many : :one
          when 1 then :one
          else        :many
        end
      entry = entry[mode] unless false?(opt[mode]) || !entry.key?(mode)
    end

    # Honor override of displayed unit names.
    units = config_interpolations(**i_opt)
    apply_config_interpolations(entry, units: units)
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

  # config_lookup_paths
  #
  # @param [Symbol, String] ctrlr
  # @param [Symbol, String] action
  # @param [String, Array]  path      Partial I18n path.
  #
  # @return [Array<Array<Symbol>>]
  #
  def config_lookup_paths(ctrlr, action, *path)
    base_paths = config_lookup_order(ctrlr, action).map! { |v| v.join('.') }
    config_flatten_order(base_paths, *path)
  end

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

  # Recursively apply supplied unit interpolations.
  #
  # @param [Hash, Array, String, Integer, Boolean, nil] item
  # @param [Hash]                                       units
  #
  # @return [Hash, Array, String, Integer, Boolean, nil]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def apply_config_interpolations(item, units:, **)
    if item.is_a?(Hash)
      item.transform_values { |v| send(__method__, v, units: units) }
    elsif item.is_a?(Array)
      item.map { |v| send(__method__, v, units: units) }
    elsif item.is_a?(String) && item.include?('%{')
      item.gsub(SPRINTF_NAMED_REFERENCE) { |s| units[$1&.to_sym] || s }
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
  # @param [Hash]                units      Specify one or more unit names.
  #
  # @option units [String] :item            Specify single unit name.
  # @option units [String] :items           Specify plural unit name.
  # @option units [String] :Item            Specify capitalized single unit.
  # @option units [String] :Items           Specify capitalized plural units.
  #
  # @return [Hash{Symbol=>String}]
  #
  # == Usage Notes
  # Specifying :item completely by-passes configuration lookup.  Specifying
  # :items, :Item, and/or :Items will simply override the matching configured
  # (or derived) value.
  #
  # == Implementation Notes
  # This method does not have an embedded fallback value -- it assumes that
  # some form of 'emma.generic.unit' will be found if there is no definition
  # for the given controller.
  #
  def config_interpolations(
    controller: nil,
    action:     nil,
    brief:      true,
    long:       false,
    mode:       nil,
    count:      nil,
    plural:     nil,
    **units
  )
    units.slice!(:item, :items, :Item, :Items)
    units.compact_blank!

    # Get the most specific definition available if none was provided.
    unless units[:item]
      mode ||= (true?(long) || false?(brief)) ? :long : :brief
      config_lookup_order(controller, action).find do |base_path|
        cfg = controller_configuration.dig(*base_path, :unit)
        cfg = cfg[mode] if cfg.is_a?(Hash)
        if cfg.is_a?(String)
          units[:item]  = cfg
        elsif cfg.is_a?(Hash)
          units[:item]  = cfg[:one]  || cfg.values.first
          units[:items] = cfg[:many] || cfg[:other]
          units[:item] || units[:items]
        end
      end
    end

    # Derive any missing values.
    units[:item]  ||= units[:Item]&.downcase  || units[:items]&.singularize
    units[:items] ||= units[:Items]&.downcase || units[:item]&.pluralize
    units[:Item]  ||= units[:item]&.capitalize
    units[:Items] ||= units[:items]&.capitalize

    # Return with all interpolation values unless limitations were indicated.
    if true?(plural)
      units.except!(:item, :Item)   unless count.to_i == 1
    else
      units.except!(:items, :Items) if false?(plural) || (count.to_i == 1)
    end
    units
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
