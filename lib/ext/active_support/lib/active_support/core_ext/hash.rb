# lib/ext/active_support/lib/active_support/core_ext/hash.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/core_ext/hash'

module HashExt

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ObjectExt
    # :nocov:
  end

  # ===========================================================================
  # :section: Instance methods to add to Hash
  # ===========================================================================

  public

  # Recursively freeze a Hash so that no part of its forest of key-value pairs
  # can be modified.
  #
  # @return [self]
  #
  # === Usage Notes
  # This should not be used in any situation where the elements are live
  # objects subject to active updating (which would be unusable if frozen).
  #
  def deep_freeze
    each { |kv_pair| kv_pair.each(&:deep_freeze) }
    freeze
  end

  # Recursive duplication.
  #
  # @return [Hash]
  #
  # === Usage Notes
  # A deeply-nested hash may reference objects that cannot or should not be
  # duplicated. To avoid that situation, a class may redefine #duplicable? to
  # return *false* (so that Object#rdup returns *self*), or a class may define
  # #rdup with customized behaviors.
  #
  # === Implementation Notes
  # Unlike ActiveSupport #deep_dup, this also ensures that other enumerables
  # like Array are also duplicated, not just copied by reference.
  #
  def rdup
    self.class[map { |k, v| [k, v.rdup] }]
  end

  # Recursive merge.
  #
  # @param [Hash] other
  #
  # @return [Hash]
  #
  def rmerge(other)
    rdup.rmerge!(other)
  end

  # Recursive merge into self.
  #
  # If *other* is a Hash, then its pairs are merged into *self*; if *other* is
  # any other value, it is ignored (unless *raise_error* is *true*).
  #
  # @param [Hash]    other
  # @param [Boolean] raise_error      If *true*, raise exceptions.
  #
  # @raise [RuntimeError]             If *other* is not a Hash.
  #
  # @return [self]
  #
  def rmerge!(other, raise_error = false)
    if other.is_a?(Hash)
      other.each_pair do |k, v|
        key = (k if key?(k)) || (k.to_sym if key?(k.to_sym))
        if key && self[key].is_a?(Enumerable)
          self[key].rmerge!(v)
        else
          self[key || k] = v.rdup
        end
      end
    elsif raise_error
      raise "#{other.class} invalid"
    end
    self
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  # If there is ever a time when Rails or the standard Ruby library defines
  # one of these extension methods, any current uses of the method needs to be
  # evaluated and the local definition should be removed.
  if sanity_check?
    errors = instance_methods.intersection(Hash.instance_methods)
    fail 'Hash already defines %s' % errors.join(', ') if errors.present?
  end

end

class Hash
  include HashExt
end

__loading_end(__FILE__)
