# app/records/concerns/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared values and methods.
#
module Api::Common
  # TODO: ???
end

# =============================================================================
# Definitions of new fundamental "types"
# =============================================================================

public

# noinspection RubyConstantNamingConvention
Boolean = Axiom::Types::Boolean

# Base class for custom scalar types.
#
class ScalarType

  attr_reader :value

  delegate_missing_to :value

  def initializer(v = nil, *)
    set(v)
  end

  def value=(v)
    set(v)
  end

  def set(v)
    v_normalized = normalize(v)
    acceptable   = v_normalized.nil? || valid?(v_normalized)
    Log.error("#{self.class}: #{v.inspect}") unless acceptable
    @value = acceptable && v_normalized || default
  end

  def valid?(v = nil)
    (v || @value).present?
  end

  def to_s
    @value.to_s
  end

  def inspect
    "(#{to_s.inspect})"
  end

  def default
    self.class.default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  def normalize(v)
    v&.to_s&.strip
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  def self.default
    ''
  end

end

# ISO 8601 duration.
#
class IsoDuration < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    v = v&.to_s&.strip || @value
    v.match?(/^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?)?$/)
  end

end

# ISO 8601 general date.
#
class IsoDate < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    year?(v) || day?(v) ||
      (v&.to_s&.strip || @value).match?(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dTZD$/)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def year?(v = nil)
    v = v&.to_s&.strip || @value
    v.match?(/^\d{4}$/)
  end

  def day?(v = nil)
    v = v&.to_s&.strip || @value
    v.match?(/^\d{4}-\d\d-\d\d$/)
  end

end

# ISO 8601 year.
#
class IsoYear < IsoDate

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    year?(v)
  end

end

# ISO 8601 day.
#
class IsoDay < IsoDate

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    day?(v)
  end

end

# ISO 639-2 alpha-3 language code.
#
class IsoLanguage < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    v = normalize(v) || @value
    ISO_639.find_by_code(v).present?
  end

end

# Base class for enumeration scalar types.
#
class EnumType < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def set(v)
    # noinspection RubyAssignmentExpressionInConditionalInspection
    unless v.nil? || valid?(v = v.to_s.strip)
      Log.warn("#{type}: #{v.inspect}: not in #{values}")
      v = nil
    end
    @value = v || default
  end

  def valid?(v = @value)
    values.include?(v.to_s)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of the represented enumeration type.
  #
  # @return [Array<String>]
  #
  def type
    self.class.type
  end

  # The enumeration values associated with the instance.
  #
  # @return [Array<String>]
  #
  def values
    self.class.values
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The name of the represented enumeration type.
  #
  # @return [Symbol]
  #
  def self.type
    @type ||= self.to_s.to_sym
  end

  # The enumeration values associated with the subclass.
  #
  # @return [Array<String>]
  #
  def self.values
    @values ||= enumeration_lookup(:values)
  end

  # Called from API record definitions to provide this base class with the
  # values that will be accessed implicitly from subclasses.
  #
  # @param [Hash{Symbol=>Hash}] new_entries
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def self.add_enumerations(new_entries)
    enumerations.merge!(new_entries || {})
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # The default value associated with this enumeration type.  If no default is
  # explicitly defined the initial value is returned.
  #
  # @return [String]
  #
  def self.default
    @default ||= enumeration_lookup(:default) || values&.first
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Enumeration definitions accumulated from API records.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # == Implementation Note
  # This needs to be a class variable so that all subclasses reference the same
  # set of values.
  #
  def self.enumerations
    @@enumerations ||= {}
  end

  # Lookup a property associated with an enumeration.
  #
  # @param [Symbol] key               Either :values or :default.
  # @param [Symbol] entry
  #
  # @return [Array<String>]           Result for key == :values.
  # @return [String]                  Result for key == :default.
  # @return [nil]
  #
  # @see Bs::Api::Common#ENUMERATIONS
  # @see Search::Api::Common#ENUMERATIONS
  #
  def self.enumeration_lookup(key, entry = nil)
    entry ||= type
    enumerations.dig(entry, key)
  end

end

__loading_end(__FILE__)
