# app/models/concerns/api/serializer/xml_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process XML data.
#
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::XmlBase < Api::Serializer::Base

  include Representable::XML
  include Representable::Coercion
  include Api::Serializer::XmlAssociations

  # ===========================================================================
  # :section: Api::Serializer::Base overrides
  # ===========================================================================

  public

  # Render data elements in XML format.
  #
  # @param [Symbol, Proc, nil] method   Default: :to_xml
  # @param [Hash]              opt      Options argument for *method*.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Api::Serializer::Base#serialize
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
  # This method overrides:
  # @see Api::Serializer::Base#deserialize
  #
  def deserialize(data, method = :from_xml)
    super
  end

  # ===========================================================================
  # :section: Api::Serializer::Base overrides
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
  # @see Api::Serializer::Base#set_source_data
  #
  def set_source_data(data)
    @source_data ||=
      if data.is_a?(String)
        data.dup
      elsif data
        data.to_xml
      end
  end

  # ===========================================================================
  # :section: Record field schema DSL
  # ===========================================================================

  public

  if defined?(XML_ELEMENT_NAMING_MODE)
    defaults do |name|
      { as: element_name(name, XML_ELEMENT_NAMING_MODE) }
    end
  end

end

__loading_end(__FILE__)
