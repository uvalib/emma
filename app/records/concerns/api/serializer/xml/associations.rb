# app/records/concerns/api/serializer/xml/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides to Api::Serializer::Associations for XML serializers.
#
module Api::Serializer::Xml::Associations

  extend ActiveSupport::Concern

  module ClassMethods

    include ::Api::Serializer::Xml::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # XML-specific operations for #attribute data elements.
    #
    # @param [String, Symbol]        name
    # @param [String, Symbol, Class] element
    # @param [Hash]                  options
    #
    # @return [void]
    #
    # This method replaces:
    # @see Api::Serializer::Associations#prepare_attribute!
    #
    def prepare_attribute!(name, element, options)
      super
      if options[:attribute].is_a?(FalseClass)
        options.delete(:attribute)
      elsif IMPLICIT_ATTRIBUTES && !options.key?(:attribute)
        options[:attribute] = true
      end
      options[:as] ||= attribute_render_name(name)
    end

    # XML-specific operations for #has_one data elements.
    #
    # @param [String, Symbol]        name
    # @param [String, Symbol, Class] element
    # @param [Hash]                  options
    #
    # @return [void]
    #
    # This method replaces:
    # @see Api::Serializer::Associations#prepare_one!
    #
    def prepare_one!(name, element, options)
      super
      options.delete(:wrap) if boolean?(options[:wrap])
      options[:as] ||= element_render_name(element)
    end

    # XML-specific operations for #has_many data elements.
    #
    # @param [String, Symbol]        wrapper
    # @param [String, Symbol, Class] element
    # @param [Hash]                  options
    #
    # @option options [Boolean] :wrap
    #
    # If options[:wrap] is *true* then it will be replaced by the *wrapper*;
    # this forces a specific collection to be wrapped even when
    # #WRAP_COLLECTIONS is *false*.
    #
    # @return [void]
    #
    # This method replaces:
    # @see Api::Serializer::Associations#prepare_collection!
    #
    def prepare_collection!(wrapper, element, options)
      super
      wrap =
        case options[:wrap]
          when false then options.delete(:wrap)
          when true  then true
          when nil   then WRAP_COLLECTIONS
          else            false # The value will be used as supplied.
        end
      options[:wrap] = element_render_name(wrapper) if wrap
      options[:as] ||= element_render_name(element)
    end

  end

end

__loading_end(__FILE__)
