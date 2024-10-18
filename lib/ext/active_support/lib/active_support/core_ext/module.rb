# lib/ext/active_support/lib/active_support/core_ext/module.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/core_ext/module'

module ModuleExt

  include SystemExtension

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include ObjectExt
  end
  # :nocov:

  # ===========================================================================
  # :section: Instance methods to add to Module
  # ===========================================================================

  public

  # Avoid inadvertent freezing of modules and classes.
  #
  # @return [self]
  #
  def deep_freeze
    self
  end

  # Report modules and classes as frozen to avoid inadvertent freezing.
  #
  def deep_frozen?
    true
  end

  # Attempt to get a constant without raising an exception.
  #
  # @param [Symbol, String] name
  # @param [Boolean]        inherit
  #
  # @return [any]                     If the constant is defined.
  # @return [nil]                     If the constant is not defined.
  #
  def safe_const_get(name, inherit = true)
    return unless name.is_a?(Symbol) || name.is_a?(String)
    const_get(name, inherit) if const_defined?(name, inherit)
  end

end

class Module

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include ModuleExt
    extend  ModuleExt
  end
  # :nocov:

  ModuleExt.include_and_extend(self)

end

__loading_end(__FILE__)
