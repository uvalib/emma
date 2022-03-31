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
  # @param [Array<Symbol>]                           keys
  #
  # @return [Array<(Hash, Hash)>]     Matching hash followed by remainder hash.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def partition_hash(hash, *keys, &block)
    keys = gather_keys(*keys, &block)
    hash = normalize_hash(hash)
    return (matched = hash.slice(*keys)), hash.except(*matched.keys)
  end

  # Retain the elements identified by *keys* in *hash* (that is, extract all
  # elements except the ones matching those keys).
  #
  # @param [ActionController::Parameters, Hash, nil] hash
  # @param [Array<Symbol>]                           keys
  #
  # @return [Hash]                    The elements removed from *hash*.
  #
  # == Usage Note
  # If *hash* is something other than a ::Hash, the original item will not be
  # changed by this method.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def remainder_hash!(hash, *keys, &block)
    keys = gather_keys(*keys, &block)
    hash = normalize_hash(hash) unless hash.class == ::Hash
    hash.slice!(*keys)
  end

  # Extract the elements identified by *keys* from *hash*.
  #
  # @param [ActionController::Parameters, Hash, nil] hash
  # @param [Array<Symbol>]                           keys
  #
  # @return [Hash]                    The elements removed from *hash*.
  #
  # == Usage Note
  # If *hash* is something other than a ::Hash, the original item will not be
  # changed by this method.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def extract_hash!(hash, *keys, &block)
    keys = gather_keys(*keys, &block)
    hash = normalize_hash(hash) unless hash.class == ::Hash
    hash.slice(*keys).tap { |matches| hash.except!(*matches.keys) }
  end

  # Extract the elements identified by *keys* from *hash*.
  alias partition_hash! extract_hash!

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
    # noinspection RubyNilAnalysis
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
  # @param [Boolean]   reduce         If *true* transform arrays with a single
  #                                     element into scalars.
  #
  # @return [Hash]
  #
  # @see #_remove_blanks
  #
  def reject_blanks(item, reduce = false)
    # noinspection RubyMismatchedReturnType
    item.is_a?(Hash) && _remove_blanks(item, reduce) || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Recursively remove blank items from an object.
  #
  # @param [Hash, Array, Any] item
  # @param [Boolean]          squeeze   If *true* transform arrays with a
  #                                       single element into scalars.
  #
  # @return [Hash, Array, Any, nil]
  #
  #--
  # == Variations
  #++
  #
  # @overload _remove_blanks(hash)
  #   @param [Hash]       hash
  #   @param [Boolean]    squeeze
  #   @return [Hash, nil]
  #
  # @overload _remove_blanks(array)
  #   @param [Array]      array
  #   @param [Boolean]    squeeze
  #   @return [Array, nil]
  #
  # @overload _remove_blanks(item)
  #   @param [FalseClass] item
  #   @param [Boolean]    squeeze     Ignored
  #   @return [FalseClass]
  #
  # @overload _remove_blanks(item)
  #   @param [Any]        item
  #   @param [Boolean]    squeeze     Ignored
  #   @return [Any, nil]
  #
  # == Usage Notes
  # Empty strings and nils are considered blank, however an item or element
  # with the explicit value of *false* is not considered blank.
  #
  def _remove_blanks(item, squeeze = false)
    meth = __method__
    case item
      when Hash
        item.transform_values { |v| send(meth, v, squeeze) }.compact.presence
      when Array
        result = item.map { |v| send(meth, v, squeeze) }.compact
        (squeeze && (result.size <= 1)) ? result.first : result.presence
      else
        # noinspection RubyMismatchedReturnType
        item.is_a?(FalseClass) ? item : item.presence
    end
  end

end

__loading_end(__FILE__)
