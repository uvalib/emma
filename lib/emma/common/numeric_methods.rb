# lib/emma/common/numeric_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::NumericMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  NUMBER_PATTERN =
    /\A\s*[-+]?\d*(_\d+)*\.?\d+(_\d+)*([eE][-+]?[0-9]+)?\s*\z/.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Interpret *value* as an integer.
  #
  # @param [String, Symbol, Numeric, *] value
  #
  # @return [Integer]
  # @return [nil]                     If *value* does not represent a number.
  #
  def to_integer(value)
    return value.round if value.is_a?(Numeric)
    value = value.to_s if value.is_a?(Symbol)
    value.to_i         if value.is_a?(String) && value.match?(NUMBER_PATTERN)
  end

  # Interpret *value* as a positive integer.
  #
  # @param [String, Symbol, Numeric, *] value
  #
  # @return [Integer]
  # @return [nil]                     If *value* <= 0 or not a number.
  #
  def positive(value)
    result = to_integer(value) or return
    result if result.positive?
  end

  # Interpret *value* as zero or a positive integer.
  #
  # @param [String, Symbol, Numeric, *] value
  #
  # @return [Integer]
  # @return [nil]                     If *value* < 0 or not a number.
  #
  def non_negative(value)
    result = to_integer(value) or return
    result unless result.negative?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Interpret *value* as a positive floating-point number.
  #
  # @param [String, Symbol, Numeric, *] value
  #
  # @return [Float]
  # @return [nil]                     If *value* does not represent a number.
  #
  def to_float(value)
    return value.to_f  if value.is_a?(Numeric)
    value = value.to_s if value.is_a?(Symbol)
    value.to_f         if value.is_a?(String) && value.match?(NUMBER_PATTERN)
  end

  # Interpret *value* as a positive floating-point number.
  #
  # @param [String, Symbol, Numeric, *] value
  # @param [Float]                      epsilon
  #
  # @return [Float]
  # @return [nil]                     If *value* <= 0 or not a number.
  #
  def positive_float(value, epsilon: nil)
    result = to_float(value) or return
    result if epsilon ? (result > +epsilon) : result.positive?
  end

  # Interpret *value* as zero or a positive floating-point number.
  #
  # @param [String, Symbol, Numeric, *] value
  # @param [Float]                      epsilon
  #
  # @return [Float]
  # @return [nil]                     If *value* <= 0 or not a number.
  #
  def non_negative_float(value, epsilon: nil)
    result = to_float(value) or return
    result unless epsilon ? (result < -epsilon) : result.negative?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given string value contains only decimal digits.
  #
  # @param [*] value
  #
  def digits_only?(value)
    case value
      when Integer, ActiveModel::Type::Integer, ActiveSupport::Duration
        true
      when String, Symbol, Numeric, ActiveModel::Type::Float
        (s = value.to_s).present? && s.delete('0-9').blank?
      else
        false
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a string of hex digits from a number-like value.
  #
  # @param [Integer, String, nil] value
  # @param [Integer]              digits  Left-zero filled if necessary.
  # @param [Boolean]              upper   If *false* show lowercase hex digits.
  #
  # @return [String]
  #
  def hex_format(value, digits: nil, upper: nil)
    hex = upper.is_a?(FalseClass) ? 'x' : 'X'
    fmt = (digits &&= positive(digits)) ? "%0#{digits}#{hex}" : "%#{hex}"
    fmt % value
  rescue ArgumentError, TypeError
    # noinspection RubyScope
    fmt % 0
  end

end

__loading_end(__FILE__)
