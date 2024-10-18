# lib/ext/active_support/lib/active_support/core_ext/object.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/core_ext/object'

module ObjectExt

  include SystemExtension

  # ===========================================================================
  # :section: Instance methods to add to Object
  # ===========================================================================

  public

  # Recursive freezing support.
  #
  # @see Hash#deep_freeze
  #
  def deep_freeze
    freeze
  end

  # Indicate whether the object and its constituent parts are frozen.
  #
  def deep_frozen?
    frozen?
  end

  # Recursive duplication support.
  #
  # @see Hash#rdup
  #
  def rdup
    duplicable? ? dup : self
  end

end

class Object

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include ObjectExt
  end
  # :nocov:

  ObjectExt.include_in(self)

end

__loading_end(__FILE__)
