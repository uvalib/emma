# lib/emma/common/boolean_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::BooleanMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Text values which represent a Boolean value.
  #
  # @type [Array<String>]
  #
  BOOL_VALUES = (TRUE_VALUES + FALSE_VALUES).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item represents a true or false value.
  #
  # @param [Boolean, String, Symbol, *] value
  #
  def boolean?(value)
    case (arg = value)
      when String then value = value.strip.downcase
      when Symbol then value = value.to_s.downcase
    end
    case value
      when true, false  then true
      when *BOOL_VALUES then true
      when *BOOL_DIGITS then Log.warn { "boolean?(#{arg.inspect}) never bool" }
    end || false
  end

end

__loading_end(__FILE__)
