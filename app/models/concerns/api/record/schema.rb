# app/models/concerns/api/record/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions used within the #schema block when it is executed in the context
# of the class which includes this module.
#
# Definition of the #schema method which defines the serializable data elements
# for the including class.
#
module Api::Record::Schema

  extend ActiveSupport::Concern

  include Api::Schema

  module ClassMethods

    include Api::Schema

    # The serializers for the including class.
    #
    # @return [Hash{Symbol=>Api::Serializer::Base}]
    #
    attr_reader :serializers

    # The JSON serializer for the including class.
    #
    # @return [Api::Serializer::Json::Base]
    #
    def json_serializer
      # noinspection RubyYardReturnMatch
      serializers[:json]
    end

    # The XML serializer for the including class.
    #
    # @return [Api::Serializer::Xml::Base]
    #
    def xml_serializer
      # noinspection RubyYardReturnMatch
      serializers[:xml]
    end

    # The Hash serializer for the including class.
    #
    # @return [Api::Serializer::Hash::Base]
    #
    def hash_serializer
      # noinspection RubyYardReturnMatch
      serializers[:hash]
    end

    # Schema definition block method.
    #
    # This method is used within the definition of a class derived from
    # Api::Record::Base to specify its serializable data elements within the
    # block supplied to the method.
    #
    # In addition, class-specific serializers are created using these data
    # element definitions.
    #
    # @param [Array<Symbol>, nil] serializer_types
    #
    # @return [Hash{Symbol=>Api::Serializer::Base}]
    #
    # @see Api::Schema#SERIALIZER_TYPES
    # @see Api::Serializer::Associations::ClassMethods#attribute
    # @see Api::Serializer::Associations::ClassMethods#has_one
    # @see Api::Serializer::Associations::ClassMethods#has_many
    #
    def schema(*serializer_types, &block)
      # Add record field definitions to the class itself.
      class_exec(&block)
      # Add record field definitions to each format-specific serializer.
      @serializers =
        (serializer_types.presence || SERIALIZER_TYPES).map { |key|
          key   = key.downcase.to_sym if key.is_a?(String)
          type  = key.to_s.capitalize
          const = "#{type}Serializer"
          base  = "Api::Serializer::#{type}::Base".constantize
          serializer = Class.new(base, &block)
          remove_const(const) if const_defined?(const)
          [key, const_set(const, serializer)]
        }.to_h
    end

  end

end

__loading_end(__FILE__)
