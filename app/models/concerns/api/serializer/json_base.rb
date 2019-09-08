# app/models/concerns/api/serializer/json_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::JsonBase < Api::Serializer::Base

  include Representable::JSON
  include Representable::Coercion
  include Api::Serializer::JsonAssociations

  # ===========================================================================
  # :section: Api::Serializer::Base overrides
  # ===========================================================================

  public

  # Render data elements in JSON format.
  #
  # @param [Symbol, Proc, nil] method   Default: :to_json
  # @param [Hash]              opt      Options argument for *method*.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Api::Serializer::Base#serialize
  #
  def serialize(method = :to_json, **opt)
    super
  end

  # Load data elements from the supplied data in JSON format.
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
  def deserialize(data, method = :from_json)
    super
  end

  # ===========================================================================
  # :section: Api::Serializer::Base overrides
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
  # @see Api::Serializer::Base#set_source_data
  #
  def set_source_data(data)
    @source_data ||=
      if data.is_a?(String)
        data.dup
      elsif data
        data.to_json
      end
  end

  # ===========================================================================
  # :section: Record field schema DSL
  # ===========================================================================

  public

  if defined?(JSON_ELEMENT_NAMING_MODE)
    defaults do |name|
      { as: element_name(name, JSON_ELEMENT_NAMING_MODE) }
    end
  end

end

__loading_end(__FILE__)
