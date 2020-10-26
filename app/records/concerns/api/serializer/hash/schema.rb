# app/records/concerns/api/serializer/hash/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Hash-specific definition overrides for serialization.
#
module Api::Serializer::Hash::Schema

  include ::Api::Serializer::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  HASH_ELEMENT_PARSE_NAMING    = DEFAULT_ELEMENT_PARSE_NAMING
  HASH_ATTRIBUTE_PARSE_NAMING  = DEFAULT_ATTRIBUTE_PARSE_NAMING
  HASH_ELEMENT_RENDER_NAMING   = DEFAULT_ELEMENT_RENDER_NAMING
  HASH_ATTRIBUTE_RENDER_NAMING = DEFAULT_ATTRIBUTE_RENDER_NAMING
  HASH_RENDER_EMPTY            = DEFAULT_RENDER_EMPTY
  HASH_RENDER_NIL              = DEFAULT_RENDER_NIL

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Symbolize keys in the serialization result by default.
  #
  # @type [Boolean]
  #
  SYMBOLIZE_KEYS = true

  # ===========================================================================
  # :section: Api::Serializer::Schema overrides
  # ===========================================================================

  public

  # The naming mode for de-serializing data elements from a hash format.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_parse_naming
    HASH_ELEMENT_PARSE_NAMING
  end

  # The naming mode for serializing attributes from a hash format.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_parse_naming
    HASH_ATTRIBUTE_PARSE_NAMING
  end

  # The naming mode for serializing data elements to a hash format.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_render_naming
    HASH_ELEMENT_RENDER_NAMING
  end

  # The naming mode for serializing attributes to a hash format.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_render_naming
    HASH_ATTRIBUTE_RENDER_NAMING
  end

  # The policy for serializing empty collections to a hash format.
  #
  def render_empty?
    HASH_RENDER_EMPTY
  end

  # The policy for serializing empty elements to hash format.
  #
  def render_nil?
    HASH_RENDER_NIL
  end

end

__loading_end(__FILE__)
