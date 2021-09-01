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
  # @param [Hash]         hash
  # @param [Boolean, nil] arrays      If *true*, convert hashes within arrays.
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
  # @param [Symbol, String, Class, nil] name
  #
  # @return [Class]
  # @return [nil]
  #
  def to_class(name)
    # noinspection RubyMismatchedReturnType
    return name if name.nil? || name.is_a?(Class)
    c = name.to_s.underscore.delete_suffix('_controller').classify
    c.safe_constantize or Log.warn { "#{__method__}: #{name.inspect} invalid" }
  end

end

__loading_end(__FILE__)
