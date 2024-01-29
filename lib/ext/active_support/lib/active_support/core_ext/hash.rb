# lib/ext/active_support/lib/active_support/core_ext/hash.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/core_ext/hash'

module HashExt

  include SystemExtension

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
  # @param [Boolean] fatal            If *true*, raise exceptions.
  #
  # @raise [RuntimeError]             If *other* is not a Hash.
  #
  # @return [self]
  #
  def rmerge!(other, fatal: false)
    if !other.is_a?(Hash)
      raise "#{other.class} invalid" if fatal
    elsif empty?
      replace(other.rdup)
    else
      other.each_pair do |k, v|
        key   = (k        if key?(k))
        key ||= (k.to_s   if k.is_a?(Symbol) && key?(k.to_s))
        key ||= (k.to_sym if k.is_a?(String) && key?(k.to_sym))
        key && self[key].try(:rmerge!, v) || merge!((key || k) => v.rdup)
      end
    end
    self
  end

  # Remove element(s).
  #
  # @param [Array] elements
  #
  # @return [self]
  #
  def remove(*elements)
    elements.flatten.each { |key| delete(key) }
    self
  end

  # Remove element(s) or return *nil* if no changes.
  #
  # @param [Array] elements
  #
  # @return [self, nil]
  #
  def remove!(*elements)
    removed = keys.intersection(elements.flatten).presence
    removed&.each { |v| delete(v) } and self
  end

  # Retain only the indicated elements.
  #
  # @param [Array] elements
  #
  # @return [self]
  #
  def keep(*elements)
    kept = slice(*elements.flatten)
    (kept.size == size) ? self : replace(kept)
  end

  # Retain only the indicated elements or return *nil* if no changes.
  #
  # @param [Array] elements
  #
  # @return [self, nil]
  #
  def keep!(*elements)
    kept = slice(*elements.flatten)
    replace(kept) unless kept.size == size
  end

end

class Hash

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include HashExt
    # :nocov:
  end

  HashExt.include_in(self)

end

__loading_end(__FILE__)
