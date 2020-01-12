# app/records/concerns/api/serializer/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::Json < ::Api::Serializer

  include ::Representable::JSON
  include ::Representable::Coercion

  include ::Api::Serializer::Json::Schema
  include ::Api::Serializer::Json::Associations

  SERIALIZER_TYPE = :json

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  # Type of serializer.
  #
  # @return [Symbol]                  Always :json.
  #
  # This method overrides:
  # @see Api::Serializer#serializer_type
  #
  def serializer_type
    SERIALIZER_TYPE
  end

  # Render data elements in JSON format.
  #
  # @param [Symbol, Proc] method
  # @param [Hash]         opt         Options argument for *method*.
  #
  # @return [String]
  #
  # @see Representable::JSON#to_json
  #
  # This method overrides:
  # @see Api::Serializer#serialize
  #
  def serialize(method: :to_json, **opt)
    super
  end

  # Load data elements from the supplied data in JSON format.
  #
  # @param [String, Hash] data
  # @param [Symbol, Proc] method
  #
  # @return [Hash]
  # @return [nil]
  #
  # @see Representable::JSON#from_json
  #
  # This method overrides:
  # @see Api::Serializer#deserialize
  #
  def deserialize(data, method: :from_json)
    super
  end

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  protected

  # Set source data string for JSON data.
  #
  # @param [String, Hash] data
  #
  # @return [String]
  # @return [nil]                 If *data* is neither a String nor a Hash.
  #
  # This method overrides:
  # @see Api::Serializer#set_source_data
  #
  def set_source_data(data)
    @source_data ||=
      if data.is_a?(String)
        data.dup
      elsif data
        data.to_json
      end
  end

end

__loading_end(__FILE__)
