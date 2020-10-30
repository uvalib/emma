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
  XML_ELEMENT_RENDER_NAMING   = :default
  XML_ATTRIBUTE_RENDER_NAMING = :default
  XML_RENDER_EMPTY            = DEFAULT_RENDER_EMPTY
  XML_RENDER_NIL              = DEFAULT_RENDER_NIL

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
  # @type [Boolean]
  #
  WRAP_COLLECTIONS = true

  # If this value is *false* then #attribute schema values are serialized
  # (rendered) as XML attributes; if *true* then they are serialized as XML
  # elements (removing the distinction between #attribute and #has_one).
  #
  # @type [Boolean]
  #
  ATTRIBUTES_AS_ELEMENTS = true

  # Mapping of class to XML type.
  #
  # @type [Hash{Class=>String}]
  #
  XML_TYPE = {
    Axiom::Types::Boolean  => 'xs:boolean',
    Axiom::Types::Date     => 'xs:date',
    Axiom::Types::DateTime => 'xs:date',
    Axiom::Types::Integer  => 'xs:integer',
    Axiom::Types::String   => 'xs:string',
    Axiom::Types::Time     => 'xs:time',
    String                 => 'xs:string',
    Integer                => 'xs:integer',
    TrueClass              => 'xs:boolean',
    FalseClass             => 'xs:boolean',
  }.freeze

  # Scalar values are expressed as strings by default.
  #
  # @type [String]
  #
  DEFAULT_XML_TYPE = 'xs:string'

  # Base set of XML namespaces to present when rendering full messages.
  #
  # @type [Hash{String=>String}]
  #
  DEFAULT_XML_NAMESPACES = {
    'xmlns'    => 'https://emma.lib.virginia.edu/schema',
    'xmlns:xs' => 'http://www.w3.org/2001/XMLSchema'
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If this value is *false* then #attribute schema values are serialized
  # (rendered) as XML attributes; if *true* then they are serialized as XML
  # elements (removing the distinction between #attribute and #has_one).
  #
  def attributes_as_elements?
    ATTRIBUTES_AS_ELEMENTS
  end

  # The set of XML namespaces.
  #
  # @type [Hash{String=>String}]
  #
  def xml_namespaces
    @xml_namespaces ||= DEFAULT_XML_NAMESPACES
  end

  # ===========================================================================
  # :section: Api::Serializer::Schema overrides
  # ===========================================================================

  public

  # The naming mode for de-serializing data elements from XML.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_parse_naming
    XML_ELEMENT_PARSE_NAMING
  end

  # The naming mode for serializing attributes from XML.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_parse_naming
    XML_ATTRIBUTE_PARSE_NAMING
  end

  # The naming mode for serializing data elements to XML.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_render_naming
    XML_ELEMENT_RENDER_NAMING
  end

  # The naming mode for serializing attributes to XML.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_render_naming
    XML_ATTRIBUTE_RENDER_NAMING
  end

  # The policy for serializing empty collections to XML.
  #
  def render_empty?
    XML_RENDER_EMPTY
  end

  # The policy for serializing empty elements to XML.
  #
  def render_nil?
    XML_RENDER_NIL
  end

  # ===========================================================================
  # :section: Api::Serializer::Schema overrides
  # ===========================================================================

  public

  # Transform *name* into the form indicated by the given naming mode.
  #
  # @param [String, Symbol, Class] name
  # @param [Symbol, nil]           mode
  #
  # @raise [StandardError]                If *mode* is invalid.
  #
  # @return [String]
  #
  def element_name(name, mode = nil)
    if (xml_type = XML_TYPE[name])
      super(xml_type)
    elsif scalar_type?(name)
      super(DEFAULT_XML_TYPE)
    else
      super(name, mode)
    end
  end

end

__loading_end(__FILE__)
