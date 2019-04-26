# lib/ext/active_support/core_ext/hash.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/core_ext/hash'

class Hash

  # Recursively freeze a Hash so that no part of its forest of key-value pairs
  # can be modified.
  #
  # @return [self]
  #
  # == Usage Notes
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
  # == Usage Notes
  # A deeply-nested hash may reference objects that cannot or should not be
  # duplicated. To avoid that situation, a class may redefine #duplicable? to
  # return *false* (so that Object#rdup returns *self*), or a class may define
  # #rdup with customized behaviors.
  #
  # == Implementation Notes
  # Although active_support defines `deep_dup` for Rails 3, that's not quite
  # adequate; while it does handle recursive duplication of Hash-valued
  # elements, it doesn't do anything with other enumerables (particularly
  # Array).
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
  # @param [Hash]                  other
  # @param [TrueClass, FalseClass] raise_error  If *true*, ArgumentException
  #                                               will be raised if *other* is
  #                                               not a Hash.
  #
  # @return [self]
  #
  def rmerge!(other, raise_error = nil)
    if other.is_a?(Hash)
      other.each_pair do |k, v|
        key = (k if key?(k)) || (k.to_sym if key?(k.to_sym))
        if key && self[key].is_a?(Enumerable)
          self[key].rmerge!(v)
        else
          key ||= k
          self[key] = v.rdup
        end
      end
    elsif raise_error
      raise ArgumentError, "#{other.class} invalid"
    end
    self
  end

end

__loading_end(__FILE__)
