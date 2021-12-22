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
  BOOLEAN_VALUES = (TRUE_VALUES + FALSE_VALUES).sort_by!(&:length).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item represents a true or false value.
  #
  # @param [Any, nil] value
  #
  def boolean?(value)
    return true  if value.is_a?(TrueClass) || value.is_a?(FalseClass)
    return false unless value.is_a?(String) || value.is_a?(Symbol)
    BOOLEAN_VALUES.include?(value.to_s.strip.downcase)
  end

end

__loading_end(__FILE__)
