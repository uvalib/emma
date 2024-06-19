# app/records/concerns/api/serializer/xml.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process XML data.
#
# @see Representable::XML
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::Xml < Api::Serializer

  include Representable::XML
  include Representable::Coercion

  include Api::Serializer::Xml::Schema
  include Api::Serializer::Xml::Associations

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  SERIALIZER_TYPE = :xml

  # The leading line of an XML document.
  #
  # @type [String]
  #
  XML_PROLOG = %q(<?xml version="1.0" encoding="UTF-8"?>).freeze

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  # Type of serializer.
  #
  # @return [Symbol]                  Always :xml.
  #
  def serializer_type
    SERIALIZER_TYPE
  end

  # Render data elements in XML format.
  #
  # @param [Symbol, Proc] method
  # @param [Hash]         opt         Options argument for *method*.
  #
  # @return [String]
  #
  # @see Representable::XML#to_xml
  #
  def serialize(method: :to_xml, **opt)
    opt[:wrap] = represented.class.name.demodulize
    xml = add_xml_namespaces(super)
    xml.start_with?(XML_PROLOG) ? xml : "#{XML_PROLOG}\n#{xml}"
  end

  # Load data elements from the supplied data in XML format.
  #
  # @param [String, Hash] data
  # @param [Symbol, Proc] method
  #
  # @return [Api::Record]
  # @return [nil]
  #
  # @see Representable::XML#from_xml
  #
  # @note The representable gem doesn't do XML namespaces (yet?).
  #
  def deserialize(data, method: :from_xml)
    self.class.remove_namespaces!
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Add XML namespaces to a copy of a top-level XML element.
  #
  # @param [String]    xml
  # @param [Hash, nil] additional     Added namespaces.
  #
  # @return [String]                  Modified XML.
  #
  def add_xml_namespaces(xml, additional: nil)
    pairs = xml_namespaces.merge(additional || {})
    attrs = pairs.map { |ns, path| %Q(#{ns}="#{path}") }
    xml.sub(/^<([^?>\n][^>\n]*)>/) { '<%s>' % [$1, *attrs].join(' ').squish }
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
  def set_source_data(data)
    # noinspection RubyMismatchedReturnType
    @source_data ||=
      if data.is_a?(String)
        data.dup
      elsif data
        data.to_xml
      end
  end

end

__loading_end(__FILE__)
