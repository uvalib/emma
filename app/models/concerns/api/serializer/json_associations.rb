# app/models/concerns/api/serializer/json_associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/serializer/associations'

# Overrides to the class methods defined in Api::Serializer::Associations for
# JSON serializers.
#
module Api::Serializer::JsonAssociations

  extend ActiveSupport::Concern

  module ClassMethods

    include Api::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # JSON-specific operations for #attribute data elements.
    #
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  options
    #
    # @return [void]
    #
    # This method replaces:
    # @see Api::Serializer::Associations#prepare_attribute!
    #
    def prepare_attribute!(_element, options)
      options.delete(:attribute)
    end

    # JSON-specific operations for #has_many data elements.
    #
    # @param [String, Symbol]        _wrapper
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  options
    #
    # @option options [TrueClass, FalseClass] :wrap
    #
    # @return [void]
    #
    # This method replaces:
    # @see Api::Serializer::Associations#prepare_collection!
    #
    def prepare_collection!(_wrapper, _element, options)
      options.delete(:wrap)
    end

  end

end

__loading_end(__FILE__)
