# app/records/concerns/api/serializer/hash.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Hash.
#
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::Hash < ::Api::Serializer

  include ::Representable::Hash
  include ::Representable::Coercion

  include ::Api::Serializer::Hash::Schema
  include ::Api::Serializer::Hash::Associations

  SERIALIZER_TYPE = :hash

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  # Type of serializer.
  #
  # @return [Symbol]                  Always :hash.
  #
  # This method overrides:
  # @see Api::Serializer#serializer_type
  #
  def serializer_type
    SERIALIZER_TYPE
  end

  # Render data elements.
  #
  # @param [Symbol, Proc, nil] method           Default: :to_hash
  # @param [Boolean, nil]      symbolize_keys
  # @param [Hash]              opt              Options argument for *method*.
  #
  # @return [String]
  #
  # @see Representable::Hash#to_hash
  #
  # This method overrides:
  # @see Api::Serializer#serialize
  #
  def serialize(method = :to_hash, symbolize_keys: SYMBOLIZE_KEYS, **opt)
    symbolize_keys ? super.deep_symbolize_keys : super
  end

  # Load data elements.
  #
  # @param [String, Hash]      data
  # @param [Symbol, Proc, nil] method
  #
  # @return [Hash]
  # @return [nil]
  #
  # @see Representable::Hash#from_hash
  #
  # This method overrides:
  # @see Api::Serializer#deserialize
  #
  def deserialize(data, method = :from_hash)
    super
  end

end

__loading_end(__FILE__)
