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
  # @param [Array<Symbol,String,Array>]              keys
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
  # @param [Array<Symbol,String,Array>]              keys
  #
  # @return [Hash]                    The elements removed from *hash*.
  #
  # == Usage Note
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
  # @param [Array<Symbol,String,Array>]              keys
  #
  # @return [Hash]                    The elements removed from *hash*.
  #
  # == Usage Note
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
    keys += Array.wrap(yield) if block_given?
    keys.flatten.compact_blank!.map!(&:to_sym).tap(&:uniq!)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # normalize_hash
  #
  # @param [ActionController::Parameters, Hash, nil] item
  #
  # @return [Hash{Symbol=>Any}]
  #
  def normalize_hash(item)
    (item&.try(:to_unsafe_h) || item)&.symbolize_keys || {}
  end

  # normalize_hash
  #
  # @param [ActionController::Parameters, Hash, nil] item
  #
  # @return [Hash{Symbol=>Any}]   The modified item itself if *item* is a Hash.
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
  # @param [Proc] block
  #
  # @return [Hash]
  #
  def sort_by(hash, &block)
    hash.sort_by(&block).to_h
  end

  # Sort a hash in-place.
  #
  # @param [Hash] hash
  # @param [Proc] block
  #
  # @return [Hash]
  #
  def sort_by!(hash, &block)
    hash.replace(sort_by(hash, &block))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Recursively remove blank items from a hash.
  #
  # @param [Hash, nil] item
  # @param [Boolean]   squeeze        If *true* transform arrays with a single
  #                                     element into scalars.
  # @param [Boolean]   dup            Ensure that the result is completely
  #                                     disentangled with the original.
  #
  # @return [Hash]
  #
  # @see #_remove_blanks
  #
  def reject_blanks(item, squeeze: false, dup: false, **)
    item.is_a?(Hash) && _remove_blanks(item, squeeze: squeeze, dup: dup) || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Recursively remove blank items from an object.
  #
  # @param [Hash, Array, Any] item
  # @param [Boolean]          squeeze   If *true* transform arrays with a
  #                                       single element into scalars.
  # @param [Boolean]          dup       Ensure that the result is completely
  #                                       disentangled with the original.
  #
  # @return [Hash, Array, Any, nil]
  #
  #--
  # == Variations
  #++
  #
  # @overload _remove_blanks(item)
  #   @param [NilClass,Boolean,Numeric,Symbol,Method,Proc,Module] item
  #   @param [Boolean] squeeze        Ignored
  #   @param [Boolean] dup            Ignored
  #   @return [NilClass,Boolean,Numeric,Symbol,Method,Proc,Module]
  #
  # @overload _remove_blanks(item, dup: bool)
  #   @param [String]  item
  #   @param [Boolean] squeeze        Ignored
  #   @param [Boolean] dup
  #   @return [String, nil]
  #
  # @overload _remove_blanks(hash, squeeze: bool, dup: bool)
  #   @param [Hash]    hash
  #   @param [Boolean] squeeze
  #   @param [Boolean] dup
  #   @return [Hash, nil]
  #
  # @overload _remove_blanks(array, squeeze: bool, dup: bool)
  #   @param [Array]   array
  #   @param [Boolean] squeeze
  #   @param [Boolean] dup
  #   @return [Array, nil]
  #
  # @overload _remove_blanks(item)
  #   @param [Any]     item
  #   @param [Boolean] squeeze        Ignored
  #   @param [Boolean] dup
  #   @return [Any, nil]
  #
  # == Usage Notes
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
      when TrueClass, FalseClass, Numeric, Symbol, Method, Proc, Module
        item
      when Hash
        opt = { squeeze: squeeze, dup: dup }
        item.transform_values { |v| _remove_blanks(v, **opt) }.compact.presence
      when Array
        opt = { squeeze: squeeze, dup: dup }
        res = item.map { |v| _remove_blanks(v, **opt) }.compact.presence
        (squeeze && (item&.size == 1)) ? res.first : res
      else
        item = item.presence
        (dup && item&.duplicable?) ? item.dup : item
    end
  end

end

__loading_end(__FILE__)
