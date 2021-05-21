# lib/ext/active_support/core_ext/module.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Module

  # Attempt to get a constant without raising an exception.
  #
  # @param [Symbol, String] name
  # @param [Boolean]        inherit
  #
  # @return [Any]                     If the constant is defined.
  # @return [nil]                     If the constant is not defined.
  #
  def safe_const_get(name, inherit = true)
    const_get(name, inherit) if const_defined?(name, inherit)
  end

end

__loading_end(__FILE__)
