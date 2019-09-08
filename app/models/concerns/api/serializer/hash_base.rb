# app/models/concerns/api/serializer/hash_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Hash.
#
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::HashBase < Api::Serializer::Base

  include Representable::Hash
  include Representable::Coercion
  include Api::Serializer::HashAssociations

  # Symbolize keys in the serialization result by default.
  #
  # @type [Boolean]
  #
  SYMBOLIZE_KEYS = true unless defined?(SYMBOLIZE_KEYS)

  # ===========================================================================
  # :section: Api::Serializer::Base overrides
  # ===========================================================================

  public

  # Render data elements.
  #
  # @param [Symbol, Proc, nil] method           Default: :to_hash
  # @param [Boolean, nil]      symbolize_keys
  # @param [Hash]              opt              Options argument for *method*.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Api::Serializer::Base#serialize
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
  # This method overrides:
  # @see Api::Serializer::Base#deserialize
  #
  def deserialize(data, method = :from_hash)
    super
  end

  # ===========================================================================
  # :section: Record field schema DSL
  # ===========================================================================

  public

  if defined?(HASH_ELEMENT_NAMING_MODE)
    defaults do |name|
      { as: element_name(name, HASH_ELEMENT_NAMING_MODE) }
    end
  end

end

__loading_end(__FILE__)
