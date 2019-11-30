# app/records/concerns/api/serializer/xml/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# XML-specific definition overrides for serialization.
#
module Api::Serializer::Xml::Schema

  include ::Api::Serializer::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  XML_ELEMENT_PARSE_NAMING    = DEFAULT_ELEMENT_PARSE_NAMING
  XML_ATTRIBUTE_PARSE_NAMING  = DEFAULT_ATTRIBUTE_PARSE_NAMING
  XML_ELEMENT_RENDER_NAMING   = DEFAULT_ELEMENT_RENDER_NAMING
  XML_ATTRIBUTE_RENDER_NAMING = DEFAULT_ATTRIBUTE_RENDER_NAMING
  XML_RENDER_EMPTY            = DEFAULT_RENDER_EMPTY
  XML_RENDER_NIL              = false

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Collections of elements can be handled in one of two ways:
  #
  # 1. WRAP_COLLECTIONS == *true*
  #
  # The collection is contained within a "wrapper" element whose tag is the
  # plural of the element name; e.g., one or more "<copy>" elements wrapped
  # inside a "<copies>" element:
  #
  #   <holding>
  #     <copies>
  #       <copy>...</copy>
  #       <copy>...</copy>
  #       <copy>...</copy>
  #     </copies>
  #   </holding>
  #
  # 2. WRAP_COLLECTIONS == *false*
  #
  # The collection of elements are repeated directly; e.g.:
  #
  #   <holding>
  #     <copy>...</copy>
  #     <copy>...</copy>
  #     <copy>...</copy>
  #   </holding>
  #
  # @type [TrueClass, FalseClass]
  #
  WRAP_COLLECTIONS = true

  # If this value is *true* then #attribute schema values are serialized
  # (rendered) as XML attributes; if *false* then they are serialized as XML
  # elements (removing the distinction between #attribute and #has_one).
  #
  # @type [TrueClass, FalseClass]
  #
  IMPLICIT_ATTRIBUTES = false

  # ===========================================================================
  # :section: Api::Schema overrides
  # ===========================================================================

  public

  # The naming mode for de-serializing data elements from XML.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  # This method overrides:
  # @see Api::Serializer::Schema#element_parse_naming
  #
  def element_parse_naming
    XML_ELEMENT_PARSE_NAMING
  end

  # The naming mode for serializing attributes from XML.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  # This method overrides:
  # @see Api::Serializer::Schema#attribute_parse_naming
  #
  def attribute_parse_naming
    XML_ATTRIBUTE_PARSE_NAMING
  end

  # The naming mode for serializing data elements to XML.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  # This method overrides:
  # @see Api::Serializer::Schema#element_render_naming
  #
  def element_render_naming
    XML_ELEMENT_RENDER_NAMING
  end

  # The naming mode for serializing attributes to XML.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  # This method overrides:
  # @see Api::Serializer::Schema#attribute_render_naming
  #
  def attribute_render_naming
    XML_ATTRIBUTE_RENDER_NAMING
  end

  # The policy for serializing empty collections to XML.
  #
  # This method overrides:
  # @see Api::Serializer::Schema#render_empty?
  #
  def render_empty?
    XML_RENDER_EMPTY
  end

  # The policy for serializing empty elements to XML.
  #
  # This method overrides:
  # @see Api::Serializer::Schema#render_nil?
  #
  def render_nil?
    XML_RENDER_NIL
  end

end

__loading_end(__FILE__)
