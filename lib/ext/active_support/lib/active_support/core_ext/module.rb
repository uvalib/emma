# lib/ext/active_support/lib/active_support/core_ext/module.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/core_ext/module'

module ModuleExt

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ObjectExt
    # :nocov:
  end

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

  # Attempt to get a constant without raising an exception.
  #
  # @param [Symbol, String] name
  # @param [Boolean]        inherit
  #
  # @return [Any]                     If the constant is defined.
  # @return [nil]                     If the constant is not defined.
  #
  def safe_const_get(name, inherit = true)
    return unless name.is_a?(Symbol) || name.is_a?(String)
    const_get(name, inherit) if const_defined?(name, inherit)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  # If there is ever a time when Rails or the standard Ruby library defines
  # one of these extension methods, any current uses of the method needs to be
  # evaluated and the local definition should be removed.
  if sanity_check?
    errors = instance_methods.intersection(Module.instance_methods)
    fail 'Module already defines %s' % errors.join(', ') if errors.present?
  end

end

class Module
  include ModuleExt
end

__loading_end(__FILE__)
