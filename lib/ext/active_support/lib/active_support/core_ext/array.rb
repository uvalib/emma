# lib/ext/active_support/lib/active_support/core_ext/array.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/core_ext/array'

module ArrayExt

  include SystemExtension

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ObjectExt
    # :nocov:
  end

  # ===========================================================================
  # :section: Instance methods to add to Array
  # ===========================================================================

  public

  # Recursively freeze an Array and all of its elements so that the contents of
  # the elements cannot be modified.
  #
  # @return [self]
  #
  # @see Hash#deep_freeze
  #
  # === Usage Notes
  # This should not be used in any situation where the elements are live
  # objects subject to active updating (which would be unusable if frozen).
  #
  def deep_freeze
    each(&:deep_freeze)
    freeze
  end

  # Recursive duplication.
  #
  # @return [Array]
  #
  # @see Hash#rdup
  #
  # === Usage Notes
  # A deeply-nested array may reference objects that cannot or should not be
  # duplicated. To avoid that situation, a class may redefine #duplicable? to
  # return *false* (so that Object#rdup returns *self*), or a class may define
  # #rdup with customized behaviors.
  #
  def rdup
    map(&:rdup)
  end

  # Recursive merge.
  #
  # @param [Array] other
  #
  # @return [Array]
  #
  def rmerge(other)
    rdup.rmerge!(other)
  end

  # Recursive merge into self.
  #
  # If *other* is an Array, then duplicates of its elements are appended to
  # *self* unless they are already present.  If *other* is any other non-nil
  # value then a duplicate of *other* is appended to *self* unless it is
  # already present.
  #
  # @param [Array, *] other
  #
  # @return [self]
  #
  # === Usage Notes
  # It is assumed that *other* is a flat array (that is, that its elements are
  # not arrays); if it is not flat, any sub-arrays will be duplicated and
  # appended to *self* unconditionally.
  #
  def rmerge!(other)
    if other.is_a?(Array)
      other.each { |v| self << v.rdup unless include?(v) }
    elsif other
      self << other.rdup unless include?(other)
    end
    self
  end

  # Remove element(s).
  #
  # Whereas `a -= b` removes elements by allocating a new array, `a.remove(b)`
  # removes elements from the instance itself.
  #
  # @param [Array] elements
  #
  # @return [self]
  #
  def remove(*elements)
    elements.flatten!
    elements.uniq!
    delete_if { |v| elements.include?(v) }
  end

end

class Array

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ArrayExt
    # :nocov:
  end

  ArrayExt.include_in(self)

end

__loading_end(__FILE__)
