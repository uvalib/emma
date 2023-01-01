# lib/emma/common/numeric_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::NumericMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Interpret *value* as a positive integer.
  #
  # @param [String, Symbol, Numeric, *] value
  #
  # @return [Integer]
  # @return [nil]                     If *value* <= 0 or not a number.
  #
  def positive(value)
    result =
      case value
        when Integer        then value
        when Numeric        then value.round
        when String, Symbol then value.to_s.to_i
        else                     0
      end
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
    result =
      case value
        when Integer        then value
        when Numeric        then value.round
        when String, Symbol then value.to_s.to_i
        else                     0
      end
    result unless result.negative?
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
    # noinspection RubyUnusedLocalVariable
    result = nil
    case value
      when Numeric        then result = value.to_f
      when String, Symbol then result = value.to_s.to_f
      else                     return
    end
    if epsilon
      result if result > epsilon
    else
      result if result.positive?
    end
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
    result =
      case value
        when Numeric        then value.to_f
        when String, Symbol then value.to_s.to_f
        else                     0.0
      end
    if epsilon
      result unless result < -epsilon
    else
      result unless result.negative?
    end
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
