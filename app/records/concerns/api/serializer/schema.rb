# app/records/concerns/api/serializer/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common definitions for serialization.
#
module Api::Serializer::Schema

  include Emma::Common

  include Api::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default naming mode for de-serialized data elements.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  DEFAULT_ELEMENT_PARSE_NAMING = :default

  # The default naming mode for de-serialized attributes.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  DEFAULT_ATTRIBUTE_PARSE_NAMING = DEFAULT_ELEMENT_PARSE_NAMING

  # The default naming mode for serialized data elements.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  DEFAULT_ELEMENT_RENDER_NAMING = :camelcase

  # The default naming mode for serialized attributes.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  DEFAULT_ATTRIBUTE_RENDER_NAMING = DEFAULT_ELEMENT_RENDER_NAMING

  # The default policy for serializing empty collections.
  #
  # @type [Boolean]
  #
  DEFAULT_RENDER_EMPTY = false

  # The default policy for serializing empty elements.
  #
  # @type [Boolean]
  #
  DEFAULT_RENDER_NIL = false

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default naming mode for serialized data elements.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_parse_naming
    DEFAULT_ELEMENT_PARSE_NAMING
  end

  # The default naming mode for serialized attributes.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_parse_naming
    DEFAULT_ATTRIBUTE_PARSE_NAMING
  end

  # The default naming mode for serialized data elements.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def element_render_naming
    DEFAULT_ELEMENT_RENDER_NAMING
  end

  # The default naming mode for serialized attributes.
  #
  # @return [Symbol]                  One of #ELEMENT_NAMING_MODES
  #
  def attribute_render_naming
    DEFAULT_ATTRIBUTE_RENDER_NAMING
  end

  # The default policy for serializing empty collections.
  #
  # @see Representable::Binding::Collection#skipable_empty_value?
  #
  def render_empty?
    DEFAULT_RENDER_EMPTY
  end

  # The default policy for serializing empty elements.
  #
  # @see Representable::Binding#skipable_empty_value?
  #
  def render_nil?
    DEFAULT_RENDER_NIL
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform *name* into the form indicated by the given naming mode.
  #
  # @param [String, Symbol, Class] name
  # @param [Symbol, nil]           mode   Default: `#element_parse_naming`.
  #
  # @return [String]
  #
  def element_parse_name(name, mode = nil)
    mode ||= element_parse_naming
    element_name(name, mode)
  end

  # Transform *name* into the form indicated by the given naming mode.
  #
  # @param [String, Symbol, Class] name
  # @param [Symbol, nil]           mode   Default: `#attribute_parse_naming`.
  #
  # @return [String]
  #
  def attribute_parse_name(name, mode = nil)
    mode ||= attribute_parse_naming
    element_name(name, mode)
  end

  # Transform *name* into the form indicated by the given naming mode.
  #
  # @param [String, Symbol, Class] name
  # @param [Symbol, nil]           mode   Default: `#element_render_naming`.
  #
  # @return [String]
  #
  def element_render_name(name, mode = nil)
    mode ||= element_render_naming
    element_name(name, mode)
  end

  # Transform *name* into the form indicated by the given naming mode.
  #
  # @param [String, Symbol, Class] name
  # @param [Symbol, nil]           mode   Default: `#attribute_render_naming`.
  #
  # @return [String]
  #
  def attribute_render_name(name, mode = nil)
    mode ||= attribute_render_naming
    element_name(name, mode)
  end

  # Transform *name* into the form indicated by the given naming mode.
  #
  # @param [String, Symbol, Class] name
  # @param [Symbol, nil]           mode
  #
  # @raise [RuntimeError]                If *mode* is invalid.
  #
  # @return [String]
  #
  def element_name(name, mode = nil)
    name = name.to_s       if name.is_a?(Symbol) || name.is_a?(Class)
    name = name.class.to_s unless name.is_a?(String)
    name = name.demodulize
    # noinspection RubyMismatchedReturnType, RubyResolve
    case mode
      when :default, nil          then name
      when :underscore            then name.underscore
      when :underscore_uppercase  then name.underscore.upcase
      when :camelcase             then name.camelcase(:lower)
      when :full_camelcase        then name.camelcase(:upper)
      when :lowercase             then name.downcase
      when :uppercase             then name.upcase
      else                             raise "invalid mode #{mode.inspect}"
    end
  end

end

__loading_end(__FILE__)
