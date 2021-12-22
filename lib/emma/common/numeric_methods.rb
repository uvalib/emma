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
  # @param [String, Symbol, Numeric, Any] value
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
  # @param [String, Symbol, Numeric, Any] value
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given string value contains only decimal digits.
  #
  # @param [Any, nil] value
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

end

__loading_end(__FILE__)
