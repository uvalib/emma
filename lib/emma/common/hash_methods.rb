# lib/emma/common/hash_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::HashMethods

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
  # @return [Array<(Hash, Hash)>]     Matching hash followed by remainder hash.
  #
  def partition_hash(hash, *keys)
    keys = gather_keys(*keys)
    hash = normalize_hash(hash)
    return (matched = hash.slice(*keys)), hash.except(*matched.keys)
  end

  # Retain the elements identified by *keys* in *hash* (that is, extract all
  # elements except the ones matching those keys).
  #
  # @param [ActionController::Parameters, Hash, nil] hash
  # @param [Array<Symbol,String,Array,nil>]          keys
  #
  # @return [Hash]                    The elements removed from *hash*.
  #
  # === Usage Notes
  # If *hash* is something other than a ::Hash, the original item will not be
  # changed by this method.
  #
  def remainder_hash!(hash, *keys)
    keys = gather_keys(*keys)
    hash = normalize_hash(hash) unless hash.class == ::Hash
    hash.slice!(*keys)
  end

  # Extract the elements identified by *keys* from *hash*.
  #
  # @param [ActionController::Parameters, Hash, nil] hash
  # @param [Array<Symbol,String,Array,nil>]          keys
  #
  # @return [Hash]                    The elements removed from *hash*.
  #
  # === Usage Notes
  # If *hash* is something other than a ::Hash, the original item will not be
  # changed by this method.
  #
  def extract_hash!(hash, *keys)
    keys = gather_keys(*keys)
    hash = normalize_hash(hash) unless hash.class == ::Hash
    hash.slice(*keys).tap { |matches| hash.except!(*matches.keys) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def gather_keys(*keys)
    keys.concat(Array.wrap(yield)) if block_given?
    keys.flatten.compact_blank!.map!(&:to_sym).uniq
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # normalize_hash
  #
  # @param [ActionController::Parameters, Hash, nil] item
  #
  # @return [Hash{Symbol=>*}]         A new normalized Hash.
  #
  def normalize_hash(item)
    (item&.try(:to_unsafe_h) || item)&.symbolize_keys || {}
  end

  # normalize_hash
  #
  # @param [ActionController::Parameters, Hash, nil] item
  #
  # @return [Hash{Symbol=>*}]     The modified item itself if *item* is a Hash.
  #
  def normalize_hash!(item)
    new_item = normalize_hash(item)
    (item.class == ::Hash) ? item.replace(new_item) : new_item
  end

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
  # @param [Hash, *] item
  # @param [Boolean] squeeze          If *true* transform arrays with a single
  #                                     element into scalars.
  # @param [Boolean] dup              Ensure that the result is completely
  #                                     disentangled with the original.
  #
  # @return [Hash]                    A copy of *item*, possibly modified.
  #
  # @see #_remove_blanks
  #
  def reject_blanks(item, squeeze: false, dup: false, **)
    item.is_a?(Hash) && _remove_blanks(item, squeeze: squeeze, dup: dup) || {}
  end

  # Recursively remove blank items from a hash.
  #
  # @param [Hash, *] item
  # @param [Boolean] squeeze          If *true* transform arrays with a single
  #                                     element into scalars.
  #
  # @return [Hash]                    *item*, possibly modified.
  #
  # @see #_remove_blanks!
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
  # @param [Hash, Array, *] item
  # @param [Boolean]        squeeze   If *true* transform arrays with a single
  #                                     element into scalars.
  # @param [Boolean]        dup       Ensure that the result is completely
  #                                     disentangled with the original.
  #
  # @return [*]
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
  #     a[:c].new.is_a?(User)
  #     !b[:c].new.is_a?(User)
  #   ```
  #
  def _remove_blanks(item, squeeze: false, dup: false, **)
    case item
      when nil, true, false, Method, Module, Numeric, Proc, Symbol
        # noinspection RubyMismatchedReturnType
        item
      when Hash
        opt = { squeeze: squeeze, dup: dup }
        item.transform_values { |v| _remove_blanks(v, **opt) }.compact.presence
      when Array
        opt  = { squeeze: squeeze, dup: dup }
        item = item.map { |v| _remove_blanks(v, **opt) }.compact
        (squeeze && (item.size == 1)) ? item.first.presence : item.presence
      else
        item = item.presence
        (dup && item&.duplicable?) ? item.dup : item
    end
  end

  # Recursively remove blank items from an object.
  #
  # @param [Hash, Array, *] item
  # @param [Boolean]        squeeze   If *true* transform arrays with a single
  #                                     element into scalars.
  # @param [Boolean]        nil_hash  *true* except at the top-level.
  #
  # @return [*]
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
        # noinspection RubyMismatchedReturnType
        item
      when Hash
        opt = { squeeze: squeeze, nil_hash: true }
        item.transform_values! { |v| _remove_blanks!(v, **opt) }.compact!
        nil_hash ? item.presence : item
      when Array
        opt = { squeeze: squeeze, nil_hash: true }
        item.map! { |v| _remove_blanks!(v, **opt) }.compact!
        (squeeze && (item.size == 1)) ? item.first.presence : item.presence
      else
        item.presence
    end
  end

end

__loading_end(__FILE__)
