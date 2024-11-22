# app/records/concerns/api/serializer/obj/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Obj-specific definition overrides for serialization.
#
module Api::Serializer::Obj::Schema

  include Api::Serializer::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  OBJ_ELEMENT_PARSE_NAMING    = DEFAULT_ELEMENT_PARSE_NAMING
  OBJ_ATTRIBUTE_PARSE_NAMING  = DEFAULT_ATTRIBUTE_PARSE_NAMING
  OBJ_ELEMENT_RENDER_NAMING   = DEFAULT_ELEMENT_RENDER_NAMING
  OBJ_ATTRIBUTE_RENDER_NAMING = DEFAULT_ATTRIBUTE_RENDER_NAMING
  OBJ_RENDER_EMPTY            = DEFAULT_RENDER_EMPTY
  OBJ_RENDER_NIL              = DEFAULT_RENDER_NIL

  # ===========================================================================
  # :section: Api::Serializer::Schema overrides
  # ===========================================================================

  public

  # The naming mode for de-serializing data elements from Obj format.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  # @note Currently used only by #element_parse_name.
  # :nocov:
  def element_parse_naming
    OBJ_ELEMENT_PARSE_NAMING
  end
  # :nocov:

  # The naming mode for serializing attributes from Obj format.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  # @note Currently used only by #attribute_parse_name.
  # :nocov:
  def attribute_parse_naming
    OBJ_ATTRIBUTE_PARSE_NAMING
  end
  # :nocov:

  # The naming mode for serializing data elements to Obj format.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_render_naming
    OBJ_ELEMENT_RENDER_NAMING
  end

  # The naming mode for serializing attributes to Obj format.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_render_naming
    OBJ_ATTRIBUTE_RENDER_NAMING
  end

  # The policy for serializing empty collections to Obj format.
  #
  def render_empty?
    OBJ_RENDER_EMPTY
  end

  # The policy for serializing empty elements to Obj format.
  #
  def render_nil?
    OBJ_RENDER_NIL
  end

end

__loading_end(__FILE__)
