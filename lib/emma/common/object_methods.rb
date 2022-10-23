# lib/emma/common/object_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma::Common::ObjectMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a hash into a struct recursively.  (Any hash value which is
  # itself a hash will be converted to a struct).
  #
  # @param [Hash]    hash
  # @param [Boolean] arrays           If *true*, convert hashes within arrays.
  #
  # @return [Struct]
  #
  def struct(hash, arrays = false)
    keys   = hash.keys.map(&:to_sym)
    values = hash.values_at(*keys)
    values.map! do |v|
      case v
        when Array then arrays ? v.map { |elem| struct(elem, arrays) } : v
        when Hash  then struct(v, arrays)
        else            v
      end
    end
    Struct.new(*keys).new(*values)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Translate a item into a class.
  #
  # @param [Symbol, String, Class, *] item
  #
  # @return [Class, nil]
  #
  def to_class(item)
    return item if item.nil? || item.is_a?(Class)
    name = item.is_a?(Symbol) ? item.to_s : item
    name = name.class.to_s unless name.is_a?(String)
    name.underscore.delete_suffix('_controller').classify.safe_constantize or
      Log.warn { "#{__method__}: invalid: #{item.inspect}" }
  end

end

__loading_end(__FILE__)
