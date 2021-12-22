# app/records/concerns/api/serializer/obj/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides for Obj serializers.
#
module Api::Serializer::Obj::Associations

  extend ActiveSupport::Concern

  module ClassMethods

    include Api::Serializer::Obj::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # Obj-specific operations for #attribute data elements.
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
      options.delete(:attribute)
    end

    # Obj-specific operations for #has_one data elements.
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
    end

    # Obj-specific operations for #has_many data elements.
    #
    # @param [String, Symbol]        wrapper
    # @param [String, Symbol, Class] element
    # @param [Hash]                  options
    #
    # @option options [Boolean] :wrap
    #
    # @return [void]
    #
    # This method replaces:
    # @see Api::Serializer::Associations#prepare_collection!
    #
    def prepare_collection!(wrapper, element, options)
      super
      options.delete(:wrap) if boolean?(options[:wrap])
    end

  end

end

__loading_end(__FILE__)
