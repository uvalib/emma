# app/records/concerns/api/serializer/hash.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Hash.
#
# @see Representable::Hash
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::Hash < Api::Serializer

  include Representable::Hash
  include Representable::Coercion

  include Api::Serializer::Hash::Schema
  include Api::Serializer::Hash::Associations

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  SERIALIZER_TYPE = :hash

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  # Type of serializer.
  #
  # @return [Symbol]                  Always :hash.
  #
  def serializer_type
    SERIALIZER_TYPE
  end

  # Render data elements.
  #
  # @param [Symbol, Proc] method
  # @param [Boolean]      symbolize_keys
  # @param [Hash]         opt             Options argument for *method*.
  #
  # @return [String]
  #
  # @see Representable::Hash#to_hash
  #
  def serialize(method: :to_hash, symbolize_keys: SYMBOLIZE_KEYS, **opt)
    result = super(method: method, **opt)
    result = result.deep_symbolize_keys if symbolize_keys
    result
  end

  # Load data elements.
  #
  # @param [String, Hash] data
  # @param [Symbol, Proc] method
  #
  # @return [Api::Record]
  # @return [nil]
  #
  # @see Representable::Hash#from_hash
  #
  def deserialize(data, method: :from_hash)
    super
  end

end

__loading_end(__FILE__)
