# app/records/concerns/api/serializer/json/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides to Api::Serializer::Associations for JSON serializers.
#
#--
# noinspection DuplicatedCode
#++
module Api::Serializer::Json::Associations

  extend ActiveSupport::Concern

  module ClassMethods

    include ::Api::Serializer::Json::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # JSON-specific operations for #attribute data elements.
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

    # JSON-specific operations for #has_one data elements.
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

    # JSON-specific operations for #has_many data elements.
    #
    # @param [String, Symbol]        wrapper
    # @param [String, Symbol, Class] element
    # @param [Hash]                  options
    #
    # @option options [TrueClass, FalseClass] :wrap
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
