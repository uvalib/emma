# app/records/concerns/api/serializer/xml.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process XML data.
#
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::Xml < Api::Serializer

  include ::Representable::XML
  include ::Representable::Coercion

  include ::Api::Serializer::Xml::Schema
  include ::Api::Serializer::Xml::Associations

  SERIALIZER_TYPE = :xml

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  # Type of serializer.
  #
  # @return [Symbol]                  Always :xml.
  #
  # This method overrides:
  # @see Api::Serializer#serializer_type
  #
  def serializer_type
    SERIALIZER_TYPE
  end

  # Render data elements in XML format.
  #
  # @param [Symbol, Proc, nil] method   Default: :to_xml
  # @param [Hash]              opt      Options argument for *method*.
  #
  # @return [String]
  #
  # @see Representable::XML#to_xml
  #
  # This method overrides:
  # @see Api::Serializer#serialize
  #
  def serialize(method = :to_xml, **opt)
    super
  end

  # Load data elements from the supplied data in XML format.
  #
  # @param [String, Hash]      data
  # @param [Symbol, Proc, nil] method
  #
  # @return [Hash]
  # @return [nil]
  #
  # @see Representable::XML#from_xml
  #
  # This method overrides:
  # @see Api::Serializer#deserialize
  #
  def deserialize(data, method = :from_xml)
    super
  end

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  protected

  # Set source data string for XML data.
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
        data.to_xml
      end
  end

end

__loading_end(__FILE__)
