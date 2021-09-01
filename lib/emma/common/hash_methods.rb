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
  # @return [(Hash, Hash)]            Matching hash followed by remainder hash.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def partition_hash(hash, *keys)
    hash ||= {}
    hash = request_parameters(hash) if hash.is_a?(ActionController::Parameters)
    keys += Array.wrap(yield) if block_given?
    keys = keys.flatten
    keys.compact_blank!.map!(&:to_sym).uniq!
    matches     = hash.slice(*keys)
    non_matches = hash.except(*matches.keys)
    return matches, non_matches
  end

  # Extract the elements identified by *keys* from *hash*.
  #
  # @param [ActionController::Parameters, Hash, nil] hash
  # @param [Array<Symbol>]                           keys
  #
  # @return [Hash]                    The elements removed from *hash*.
  #
  def partition_hash!(hash, *keys)
    hash ||= {}
    hash = request_parameters(hash) if hash.is_a?(ActionController::Parameters)
    keys += Array.wrap(yield) if block_given?
    keys = keys.flatten
    keys.compact_blank!.map!(&:to_sym).uniq!
    # noinspection RubyNilAnalysis
    hash.slice(*keys).tap { |matches| hash.except!(*matches.keys) }
  end

  # Recursively remove blank items from a hash.
  #
  # @param [Hash, nil]    item
  # @param [Boolean, nil] reduce      If *true* transform arrays with a single
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
  # @param [Hash, Array, *] item
  # @param [Boolean, nil]   squeeze   If *true* transform arrays with a single
  #                                     element into scalars.
  #
  # @return [Hash, Array, *]
  #
  # == Variations
  #
  # @overload _remove_blanks(hash)
  #   @param [Hash]         hash
  #   @param [Boolean, nil] squeeze
  #   @return [Hash, nil]
  #
  # @overload _remove_blanks(array)
  #   @param [Array]        array
  #   @param [Boolean, nil] squeeze
  #   @return [Array, nil]
  #
  # @overload _remove_blanks(item)
  #   @param [*]            item
  #   @param [Boolean, nil] squeeze
  #   @return [*]
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
