# app/helpers/params_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Time and time span methods.
#
module ParamsHelper

  def self.included(base)
    __included(base, '[ParamsHelper]')
  end

  TRUE_VALUES  = %w(1 yes true).freeze
  FALSE_VALUES = %w(0 no false).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item represents a true value.
  #
  # @param [String, Boolean] value
  #
  def true?(value)
    TRUE_VALUES.include?(value.to_s.strip.downcase)
  end

  # Indicate whether the item represents a true value.
  #
  # @param [String, Boolean] value
  #
  def false?(value)
    FALSE_VALUES.include?(value.to_s.strip.downcase)
  end

end

__loading_end(__FILE__)
