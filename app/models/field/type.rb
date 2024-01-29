# app/models/field/type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for field type descriptions.
#
class Field::Type

  include Emma::Constants
  include Emma::TypeMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The class for the value of the Type instance.
  #
  # If this a derivative of EnumType then `base.values` defines the set of
  # possible values.
  #
  # If it's something else (String by default) then it defines the type of
  # value that may be associated with the instance.
  #
  # @return [Class]
  #
  attr_reader :base

  # The data field associated with the instance.
  #
  # @return [Symbol]
  #
  attr_reader :field

  # The value(s) associated with the instance (empty if :base is not an
  # EnumType).
  #
  # @return [Array]
  #
  attr_reader :range

  # The raw value for this field instance.
  #
  # @return [*]
  #
  attr_reader :value

  # A positive indicator of whether the instance has been given a value.
  #
  # @return [FalseClass, TrueClass]
  #
  attr_reader :valid

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Symbol, Model, *]    src
  # @param [Symbol, nil]         field
  # @param [FieldConfig, nil]    prop
  # @param [Symbol, String, nil] model  (Only used if *prop* is missing.)
  # @param [*]                   value
  #
  #--
  # noinspection RubyMismatchedVariableType
  #++
  def initialize(src, field = nil, prop: nil, model: nil, value: nil, **)
    @base  = src
    @range = nil
    # noinspection RailsParamDefResolve, RubyMismatchedArgumentType
    if (@field = field&.to_sym) && src.is_a?(Model)
      prop   ||= Field.configuration_for(field, model)
      @base    = prop[:type]
      data     = src.try(:active_emma_record) || src.try(:emma_record)
      @range ||= data.try(field)
      @range ||= (data.try(:[], field) if data.try(:key?, field))
      @range ||= src.try(field)
      @range ||= src.try(:[], field)
      @range &&= Array.wrap(@range).map { |v| v.to_s.strip }.compact_blank!
    end
    @base  = @base.to_s.safe_constantize if @base.is_a?(Symbol)
    @base  = self.class.base             unless @base.is_a?(Class)
    @value = clean(value)
    @value = @range.presence             if @value.nil?
    @valid = !@value.nil?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The resolved value for this field instance.
  #
  # @param [Boolean] labels           If *true* return labels not raw values.
  #
  # @return [Array<String>, String, nil]
  #
  def content(labels: false)
    res = value.presence || range
    res = Array.wrap(res)
    # noinspection RailsParamDefResolve
    res = res.map { |v| labels[v] || v } if labels &&= base.try(:pairs)
    (mode == :single) ? res.first : res
  end

  # Give the instance a value.
  #
  # @param [*] new_value
  #
  # @return [*]
  #
  def set(new_value)
    new_value = clean(new_value)
    @valid    = !new_value.nil?
    @value    = new_value
  end

  # Remove any value from the instance.
  #
  # @return [nil]
  #
  def clear
    set(nil)
  end

  # Indicate whether this instance is associated with a value.
  #
  def set?
    valid
  end

  # Indicate whether this instance is not associated with a value.
  #
  def unset?
    !valid
  end

  alias_method :empty?, :unset?
  alias_method :blank?, :unset?

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Resolve an item into its value.
  #
  # @param [*] v
  #
  # @return [*]
  #
  def clean(v)
    v = v[:value]            if v.is_a?(FieldConfig)
    v = v.value              if v.is_a?(Field::Type) || v.is_a?(EnumType)
    v = v.split(/[,;|\t\n]/) if v.is_a?(String)
    v = Array.wrap(v).excluding(nil, EMPTY_VALUE)
    v = v.first unless mode == :multiple
    v.presence
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Either :single or :multiple, depending on the subclass.
  #
  # @return [Symbol]
  #
  def self.mode
    safe_const_get(:MODE, true) || :single
  end

  # The enumeration type on which the subclass is based.
  #
  # @return [Class, nil]
  #
  def self.base
    safe_const_get(:BASE, true) || String
  end

  delegate :mode, to: :class

end

# =============================================================================
# :section: Subclasses for fields based on scalar values
# =============================================================================

public

# A field which may have a single value.
#
class Field::Single < Field::Type
  MODE = :single
end

# A field which may have multiple values.
#
class Field::Collection < Field::Type
  MODE = :multiple
end

# =============================================================================
# :section: Subclasses for fields based on enumerations
# =============================================================================

public

# A field based on a range of values defined by an EnumType.
#
class Field::Range < Field::Type

  # ===========================================================================
  # :section: Field::Type overrides
  # ===========================================================================

  public

  # Indicate whether this instance is unassociated with any field values.
  #
  def empty?
    super && range.blank?
  end

  # Give the instance a value.
  #
  # @param [*] new_value
  #
  # @return [Array]                 If mode == :multiple
  # @return [*]                     If mode == :single
  #
  def set(new_value)
    new_value = clean(new_value)
    return unless (@valid = !new_value.nil?)
    if mode == :multiple
      @value = [*@value, *new_value].uniq # TODO: is this right?
    else
      # noinspection RubyMismatchedReturnType
      @value = Array.wrap(new_value).first
    end
  end

end

# =============================================================================
# :section: Subclasses for fields with controlled value(s)
# =============================================================================

public

# A field which may have multiple values from a range.
#
class Field::MultiSelect < Field::Range
  MODE = :multiple
end

# A field which may have a single value from a range.
#
class Field::Select < Field::Range
  MODE = :single
end

# Special-case for a binary (true/false/unset) field.
#
class Field::Binary < Field::Select
  BASE = TrueFalse
end

__loading_end(__FILE__)
