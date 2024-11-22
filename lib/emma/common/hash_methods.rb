# lib/emma/common/hash_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::HashMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Analyze Hash extensions behavior.
  #
  # @type [Boolean]
  #
  DEBUG_HASH = true?(ENV_VAR['DEBUG_HASH'])

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Strip off the hash elements identified by *keys* to return two hashes:
  # - First, a hash containing only the requested option keys and values.
  # - Second, a copy of the original *hash* without the those keys/values.
  #
  # @param [ActionController::Parameters, Hash, nil] hash
  # @param [Array<Symbol,String,Array,nil>]          keys
  #
  # @return [Array(Hash, Hash)]       Matching hash followed by remainder hash.
  #
  def partition_hash(hash, *keys)
    keys      = keys.flatten.compact_blank.map!(&:to_sym)
    hash      = normalize_hash(hash)
    matching  = hash.slice(*keys)
    remainder = hash.except(*matching.keys)
    return matching, remainder
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform *item* into a Hash with Symbol keys.
  #
  # @param [ActionController::Parameters, Hash, nil] item
  # @param [Boolean]                                 debug
  #
  # @return [Hash{Symbol=>any,nil}]   A new normalized Hash.
  #
  def normalize_hash(item, debug: false)
    item  = item.params      if item.respond_to?(:params)
    item  = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
    valid = item.is_a?(Hash)
    if (DEBUG_HASH && !valid) || (debug && (item.class != ::Hash))
      Log.debug { "#{__method__}: #{item.class} at\n#{caller.join("\n")}" }
    elsif !valid
      Log.warn { "#{__method__}: #{item.class} unexpected: #{item.inspect}" }
    end
    valid ? item.symbolize_keys : {}
  end

  # Transform *item* in place into a Hash with Symbol keys.
  #
  # @param [ActionController::Parameters, Hash, nil] item
  #
  # @return [Hash{Symbol=>any,nil}]   Modified item itself if *item* is a Hash.
  #
  # @note Currently unused.
  # :nocov:
  def normalize_hash!(item)
    # noinspection RubyMismatchedReturnType
    if item.class != ::Hash
      normalize_hash(item, debug: DEBUG_HASH)
    elsif !item.keys.all? { _1.is_a?(Symbol) }
      item.replace(item.symbolize_keys)
    else
      item
    end
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sort a hash.
  #
  # @param [Hash] hash
  #
  # @return [Hash]
  #
  def sort(hash)
    hash.sort.to_h
  end

  # Sort a hash in-place.
  #
  # @param [Hash] hash
  #
  # @return [Hash]
  #
  def sort!(hash)
    hash.replace(sort(hash))
  end

  # Sort a hash.
  #
  # @param [Hash] hash
  # @param [Proc] blk
  #
  # @return [Hash]
  #
  def sort_by(hash, &blk)
    hash.sort_by(&blk).to_h
  end

  # Sort a hash in-place.
  #
  # @param [Hash] hash
  # @param [Proc] blk
  #
  # @return [Hash]
  #
  def sort_by!(hash, &blk)
    hash.replace(sort_by(hash, &blk))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Recursively remove blank items from a copy of a hash.
  #
  # @param [any, nil] item            Hash
  # @param [Boolean]  squeeze         If *true* transform arrays with a single
  #                                     element into scalars.
  # @param [Boolean]  dup             Ensure that the result is completely
  #                                     disentangled with the original.
  #
  # @return [Hash]                    A copy of *item*, possibly modified.
  #
  def reject_blanks(item, squeeze: false, dup: false, **)
    item.is_a?(Hash) && _remove_blanks(item, squeeze: squeeze, dup: dup) || {}
  end

  # Recursively remove blank items from a hash.
  #
  # @param [any, nil] item            Hash
  # @param [Boolean]  squeeze         If *true* transform arrays with a single
  #                                     element into scalars.
  #
  # @return [Hash]                    *item*, possibly modified.
  #
  def reject_blanks!(item, squeeze: false, **)
    item.is_a?(Hash) ? _remove_blanks!(item, squeeze: squeeze) : {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Recursively remove blank items from an object copy.
  #
  # @param [any, nil] item            Hash, Array
  # @param [Boolean]  squeeze         If *true* transform arrays with a single
  #                                     element into scalars.
  # @param [Boolean]  dup             Ensure that the result is completely
  #                                     disentangled with the original.
  #
  # @return [any, nil]
  #
  # === Usage Notes
  # * Empty strings and nils are considered blank, however an item or element
  #   with the explicit value of *false* is not considered blank.
  # * The *dup* option does not apply to items with type Proc or Module because
  #   this could lead to unexpected results, especially if the item is a class.
  #   E.g.:
  #   ```
  #     a = { c: User }
  #     b = a.deep_dup
  #     (a[:c] != b[:c])        # Different classes with the same attributes...
  #     !(b[:c] <= a[:c])       # ... which are completely unrelated.
  #     a[:c].new.is_a? (User)
  #     !b[:c].new.is_a? (User)
  #   ```
  #
  def _remove_blanks(item, squeeze: false, dup: false, **)
    case item
      when nil, true, false, Method, Module, Numeric, Proc, Symbol
        item
      when Hash
        opt = { squeeze: squeeze, dup: dup }
        item.transform_values { _remove_blanks(_1, **opt) }.compact.presence
      when Array
        opt  = { squeeze: squeeze, dup: dup }
        item = item.map { _remove_blanks(_1, **opt) }.compact
        (squeeze && (item.size == 1)) ? item.first.presence : item.presence
      else
        item = item.presence
        (dup && item&.duplicable?) ? item.dup : item
    end
  end

  # Recursively remove blank items from an object.
  #
  # @param [any, nil] item            Hash, Array
  # @param [Boolean]  squeeze         If *true* transform arrays with a single
  #                                     element into scalars.
  # @param [Boolean]  nil_hash        *true* except at the top-level.
  #
  # @return [any, nil]
  #
  # === Usage Notes
  # * Empty strings and nils are considered blank, however an item or element
  #   with the explicit value of *false* is not considered blank.
  # * The *nil_hash* option is *false* at the top-level since the *item* being
  #   modified must continue to exist.
  #
  def _remove_blanks!(item, squeeze: false, nil_hash: false, **)
    case item
      when nil, true, false, Method, Module, Numeric, Proc, Symbol
        item
      when Hash
        opt = { squeeze: squeeze, nil_hash: true }
        item.transform_values! { _remove_blanks!(_1, **opt) }.compact!
        nil_hash ? item.presence : item
      when Array
        opt = { squeeze: squeeze, nil_hash: true }
        item.map! { _remove_blanks!(_1, **opt) }.compact!
        (squeeze && (item.size == 1)) ? item.first.presence : item.presence
      else
        item.presence
    end
  end

end

__loading_end(__FILE__)
