# app/records/concerns/api/serializer/json/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# JSON-specific definition overrides for serialization.
#
module Api::Serializer::Json::Schema

  include Api::Serializer::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  JSON_ELEMENT_PARSE_NAMING    = DEFAULT_ELEMENT_PARSE_NAMING
  JSON_ATTRIBUTE_PARSE_NAMING  = DEFAULT_ATTRIBUTE_PARSE_NAMING
  JSON_ELEMENT_RENDER_NAMING   = DEFAULT_ELEMENT_RENDER_NAMING
  JSON_ATTRIBUTE_RENDER_NAMING = DEFAULT_ATTRIBUTE_RENDER_NAMING
  JSON_RENDER_EMPTY            = DEFAULT_RENDER_EMPTY
  JSON_RENDER_NIL              = DEFAULT_RENDER_NIL

  # ===========================================================================
  # :section: Api::Serializer::Schema overrides
  # ===========================================================================

  public

  # The naming mode for de-serializing data elements from JSON.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_parse_naming
    JSON_ELEMENT_PARSE_NAMING
  end

  # The naming mode for serializing attributes from JSON.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_parse_naming
    JSON_ATTRIBUTE_PARSE_NAMING
  end

  # The naming mode for serializing data elements to JSON.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_render_naming
    JSON_ELEMENT_RENDER_NAMING
  end

  # The naming mode for serializing attributes to JSON.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_render_naming
    JSON_ATTRIBUTE_RENDER_NAMING
  end

  # The policy for serializing empty collections to JSON.
  #
  def render_empty?
    JSON_RENDER_EMPTY
  end

  # The policy for serializing empty elements to JSON.
  #
  def render_nil?
    JSON_RENDER_NIL
  end

end

__loading_end(__FILE__)
