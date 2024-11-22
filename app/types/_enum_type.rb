# app/types/_enum_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for controlled-vocabulary scalar types.
#
class EnumType < ScalarType

  # All type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  CONFIGURATION = config_section(:type).deep_freeze

  # Generic type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  GENERIC_TYPES = CONFIGURATION[:generic]

  # Account-related type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ACCOUNT_TYPES = CONFIGURATION[:account]

  # Search-related type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_TYPES = CONFIGURATION[:search]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Comparable

    # Transform a value into a string for liberal case-insensitive comparison
    # where non-alphanumeric are disregarded.
    #
    # @param [String, Symbol, nil] key
    #
    # @return [String]
    #
    def comparable(key)
      key.to_s.downcase.remove!(/[_\W]/)
    end

    # Create a mapping of comparable values to original values.
    #
    # @param [Array, Hash]         keys
    # @param [String, Symbol, nil] caller   For diagnostics.
    #
    # @return [Hash{String=>String,Symbol}]
    #
    def comparable_map(keys, caller = nil)
      keys = keys.keys if keys.is_a?(Hash)
      keys.map { [comparable(_1), _1] }.to_h.tap do |result|
        unless (rs = result.size) == (ks = keys.size)
          # This is a "can't happen" situation where two original values
          # transform to the same comparable value.
          caller ||= __method__
          Log.error { "#{caller}: #{rs} map keys != #{ks} original keys" }
          Log.info  { "#{caller}: map keys: #{result.keys.inspect}" }
          Log.info  { "#{caller}: original: #{keys.inspect}" }
        end
      end
    end

  end

  extend Comparable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Enumerations

    include Comparable

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Called from API record definitions to provide this base class with the
    # values that will be accessed implicitly from subclasses.
    #
    # @param [Hash{Symbol,String=>any,nil}] entries
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def add_enumerations(entries)
      entries =
        entries.map { |name, cfg|
          if cfg.is_a?(Hash)
            default = cfg[:_default].presence
            pairs   = cfg.except(:_default).stringify_keys
            values  = pairs.keys
          else
            default = nil
            values  = Array.wrap(cfg).map(&:to_s)
            pairs   = values.map { [_1, _1] }.to_h
          end
          name  = name.to_s.camelize.to_sym
          map   = comparable_map(values, "Enumeration #{name}")
          entry = { values: values, pairs: pairs, mapping: map }
          entry.merge!(default: default) unless default.nil?
          [name, entry]
        }.to_h
      enumerations.merge!(entries)
    end

    # Enumeration definitions accumulated from API records.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    # === Implementation Notes
    # This needs to be a class variable so that all subclasses reference the
    # same set of values.
    #
    def enumerations
      # noinspection RubyClassVariableUsageInspection
      @@enumerations ||= {}
    end

    # The values for an enumeration.
    #
    # @param [Symbol, String] entry
    #
    # @return [Array<String>]
    #
    # @note Currently unused.
    # :nocov:
    def values_for(entry)
      enumerations.dig(entry.to_sym, :values)
    end
    # :nocov:

    # The value/label pairs for an enumeration.
    #
    # @param [Symbol, String] entry
    #
    # @return [Hash]
    #
    def pairs_for(entry)
      enumerations.dig(entry.to_sym, :pairs)
    end

    # The default for an enumeration.
    #
    # @param [Symbol, String] entry
    #
    # @return [String]
    #
    def default_for(entry)
      enumerations.dig(entry.to_sym, :default)
    end

  end

  extend Enumerations

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include ScalarType::Methods
    include Comparable
    extend Enumerations

    # =========================================================================
    # :section: ScalarType::Methods overrides
    # =========================================================================

    public

    # The default value associated with this enumeration type.  If no default
    # is explicitly defined the initial value is returned.
    #
    # @return [String]
    #
    def default
      entry = enumerations[type]
      entry[:default] || entry[:values]&.first
    end

    # Indicate whether *v* matches the default value.
    #
    # @param [any, nil] v
    #
    def default?(v)
      normalize(v) == default
    end

    # Indicate whether `*v*` would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      values.include?(normalize(v))
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      v = clean(v)
      return v.value if v.is_a?(self_class)
      (v = super).presence && mapping[comparable(v)] || v
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The name of the represented enumeration type.
    #
    # @return [Symbol]
    #
    def type
      self_class.to_s.to_sym
    end

    # The enumeration values associated with the subclass.
    #
    # @return [Array<String>]
    #
    def values
      enumerations.dig(type, :values)
    end

    # The value/label pairs associated with the subclass.
    #
    # @return [Hash]
    #
    # @see ApplicationRecord#pairs
    #
    def pairs(**)
      enumerations.dig(type, :pairs)
    end

    # Mapping of comparable values to enumeration values.
    #
    # @return [Hash]
    #
    def mapping
      enumerations.dig(type, :mapping)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include Methods

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Assign a new value to the instance.
  #
  # @param [any, nil]    v
  # @param [Hash] opt                 Passed to ScalarType#set
  #
  # @return [String, nil]
  #
  def set(v, **opt)
    opt.reverse_merge!(warn: true)
    super
  end

  # ===========================================================================
  # :section: EnumType::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid.
  #
  # @param [any, nil] v               Default: #value.
  #
  def valid?(v = nil)
    v ||= value
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The natural language presentation for the current enumeration value.
  #
  # @return [String]
  #
  def label
    pairs[value] || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # To be run from the subclass definition.
  #
  # The enumeration name/value pairs can be provided through a block, through
  # the *values* parameter, or by a VALUE_MAP constant defined by the subclass.
  #
  # @param [Hash{Symbol=>any}, nil] values
  #
  # @return [Hash{Symbol=>any}]
  #
  def self.define_enumeration(values = nil)
    name   = self.name.to_sym
    values = values || safe_const_get(:VALUE_MAP, false) || {}
    values = yield&.merge(values) || values    if block_given?
    Log.error "#{name}: no VALUE_MAP or block" if values.blank?
    if EnumType.enumerations.include?(name)
      Log.error "#{name}: enumeration already defined"
    else
      EnumType.add_enumerations(name => values)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.inherited(subclass)
    subclass.delegate :enumerations, to: :EnumType
    # Support `TypeName(value)` as a short-hand for `TypeName.cast(value)`.
    Object.define_method(subclass.name.to_sym) do |v, **opt|
      subclass.cast(v, **opt)
    end
  end

end

__loading_end(__FILE__)
