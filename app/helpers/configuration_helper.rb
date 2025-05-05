# app/helpers/configuration_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting "/config/locales" configuration lookup.
#
module ConfigurationHelper

  include Emma::Common

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for the current page.
  #
  # @param [String, Symbol] ctrlr     Default `params[:controller]`
  # @param [String, Symbol] action    Default `params[:action]`
  # @param [Hash]           opt       To #config_page_section.
  #
  # @return [Hash]
  #
  def current_config_page_section(ctrlr: nil, action: nil, **opt)
    action ||= params[:action].presence     or raise 'no params[:action]'
    ctrlr  ||= params[:controller].presence or raise 'no params[:controller]'
    ctrlr    = ctrlr.to_s.tr('/', '_')
    config_page_section(ctrlr, action, **opt)
  end

  # Determine the path through the configuration hierarchy for the given
  # controller/action pair.
  #
  # For ctrlr == 'user/registrations' and action == 'edit' this yields
  # %i[user_registrations edit].
  #
  # @param [String, Symbol, nil] ctrlr
  # @param [String, Symbol, nil] action
  #
  # @return [Array(Symbol, Symbol)]
  # @return [Array(Symbol, nil)]
  # @return [Array(nil,    nil)]
  #
  def config_path(ctrlr, action = nil)
    [ctrlr, action].map! { _1.to_s.underscore.tr('/.', '_').to_sym if _1 }
  end
  protected :config_path

  # controller_configuration
  #
  # @param [String, Symbol, nil] ctrlr
  # @param [String, Symbol, nil] action
  #
  # @return [Hash]
  #
  def controller_configuration(ctrlr = nil, action = nil)
    result = ApplicationHelper::CONTROLLER_CONFIGURATION
    return result unless ctrlr
    ctrlr, action = config_path(ctrlr, action)
    path = action ? [ctrlr, :action, action] : [ctrlr]
    result.dig(*path) || {}
  end
  protected :controller_configuration

  # config_lookup_order
  #
  # @param [String, Symbol, nil] ctrlr
  # @param [String, Symbol, nil] action
  #
  # @return [Array<Array<Symbol>>]
  #
  def config_lookup_order(ctrlr = nil, action = nil)
    ctrlr, action = config_path(ctrlr, action)
    result = []
    result << [ctrlr, :action, action] if ctrlr && action
    result << [ctrlr]                  if ctrlr
    result
  end
  protected :config_lookup_order

  # Find the best match from config/locales for the given partial path, first
  # looking under "en.emma.page.(ctrlr)", then under "en.emma".
  #
  # @param [String, Array]       path       Partial I18n path.
  # @param [Symbol, String, nil] ctrlr
  # @param [Symbol, String, nil] action
  # @param [any, nil]            default  Returned on failure.
  # @param [Boolean]             fatal    If *true* then raise exceptions.
  # @param [Hash]                opt      To #config_interpolations except:
  #
  # @option opt [Integer]                 :count
  # @option opt [String]                  :unit
  # @option opt [String, Symbol, Boolean] :mode
  # @option opt [Boolean]                 :one
  # @option opt [Boolean]                 :many
  #
  # @raise [RuntimeError]             If *fatal* and configuration not found.
  #
  # @return [any, nil]                The specified value or *default*.
  #
  # @example Simple path - [:item, :property]
  # Returns the most specific configuration match from the list:
  #   * "en.emma.page.(ctrlr).action.(action).item.property"
  #   * "en.emma.page.(ctrlr).item.property"
  #   * "en.emma.item.property"
  #
  # @example Branching path - [[:item1, :item2], :property]
  # Returns the most specific configuration match from the list:
  #   * "en.emma.page.(ctrlr).action.(action).item1.property"
  #   * "en.emma.page.(ctrlr).action.(action).item2.property"
  #   * "en.emma.page.(ctrlr).item1.property"
  #   * "en.emma.page.(ctrlr).item2.property"
  #   * "en.emma.item1.property"
  #   * "en.emma.item2.property"
  #
  # === Implementation Notes
  # Ideally, this method should be moved into ::Configuration, however, because
  # it takes a very different approach to constructing the list of YAML path(s)
  # to check, the functionality is not easily merged into the existing methods
  # in that module.
  #
  def config_lookup(
    *path,
    ctrlr:   nil,
    action:  nil,
    default: nil,
    fatal:   false,
    **opt
  )
    ctrlr  = opt[:controller] ||= ctrlr
    action = opt[:action]     ||= action
    entry  =
      config_lookup_paths(ctrlr, action, *path).find do |full_path|
        item = full_path.pop
        cfg  = controller_configuration.dig(*full_path)
        break cfg[item] if cfg.is_a?(Hash) && cfg.key?(item)
      end
    raise config_term(:configuration, :fail) if entry.nil? && fatal
    return default                           if entry.nil?

    # Use count-specific definitions if present.
    local = opt.extract!(:mode, :one, :many)
    if entry.is_a?(Hash) && !false?((mode = local[:mode]))
      case
        when true?(local[:many]) then mode = :many
        when true?(local[:one])  then mode = :one
        when true?(mode)         then mode = :auto
        when mode.nil?           then mode = :auto
      end
      if (mode = mode.to_sym) == :auto
        case opt[:count].to_i
          when 0 then mode = (action.to_s == 'index') ? :many : :one
          when 1 then mode = :one
          else        mode = :many
        end
      end
      entry = entry[mode] if entry.key?(mode)
    end

    # Honor override of displayed unit names.
    opt[:item] = opt.delete(:unit) if opt.key?(:unit) && !opt.key?(:item)
    apply_config_interpolations(entry, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # config_lookup_paths
  #
  # @param [Symbol, String, nil] ctrlr
  # @param [Symbol, String, nil] action
  # @param [String, Array]       path     Partial I18n path.
  #
  # @return [Array<Array<Symbol>>]
  #
  def config_lookup_paths(ctrlr, action, *path)
    base_paths = config_lookup_order(ctrlr, action).map! { _1.join('.') }
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
  # @example For path == [["a.b", "c", "d"], "e"]
  #   [["a.b", "a", "b"], "c"] -> [[:a, :b, :e], [:c, :e], [:d, :e]]
  #
  def config_flatten_order(*path, depth: 0)
    result = []
    path.map! { _1.is_a?(Array) ? _1.compact_blank : _1 }.compact_blank!
    until path.first.is_a?(Array) || path.blank?
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
      result = branches.map { [*result, *_1].flatten }
    else
      result = [result]
    end
    if depth.zero?
      result.uniq!
      result.map! do |entry|
        entry.flat_map do |item|
          if item.is_a?(String)
            item.split('.').compact_blank.map!(&:to_sym)
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
  # @param [any, nil] item            Hash, Array, String, Integer, Boolean
  # @param [Hash]     opt
  #
  # @return [any, nil]
  #
  def apply_config_interpolations(item, **opt)
    units = config_interpolations(**opt)
    deep_interpolate(item, **opt, **units)
  end

  # The variations on the description of a model item managed by a controller.
  #
  # @param [String, Symbol, nil] ctrlr
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
  # === Usage Notes
  # Specifying :item completely by-passes configuration lookup.  Specifying
  # :items, :Item, and/or :Items will simply override the matching configured
  # (or derived) value.
  #
  # === Implementation Notes
  # This method does not have an embedded fallback value -- it assumes that
  # some form of "en.emma.generic.unit" will be found if there is no definition
  # for the given controller.
  #
  def config_interpolations(
    ctrlr:  nil,
    action: nil,
    brief:  true,
    long:   false,
    mode:   nil,
    count:  nil,
    plural: nil,
    **units
  )
    ctrlr  = units[:controller] || ctrlr
    action = units[:action]     || action
    units.slice!(:item, :items, :Item, :Items)
    units.compact_blank!

    # Get the most specific definition available if none was provided.
    unless units[:item]
      mode ||= (true?(long) || false?(brief)) ? :long : :brief
      config_lookup_order(ctrlr, action).find do |base_path|
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
    base.extend(self)
  end

end

__loading_end(__FILE__)
