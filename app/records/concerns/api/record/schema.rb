# app/records/concerns/api/record/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definition of the #schema method used within the class definition to declare
# the serializable data elements associated with the class.
#
module Api::Record::Schema

  extend ActiveSupport::Concern

  module ClassMethods

    include ::Api::Schema

    # The serializers for the including class.
    #
    # @return [Hash{Symbol=>Api::Serializer}]
    #
    attr_reader :serializers

    # The JSON serializer for the including class.
    #
    # @return [Api::Serializer::Json]
    #
    def json_serializer
      # noinspection RubyYardReturnMatch
      serializers[:json]
    end

    # The XML serializer for the including class.
    #
    # @return [Api::Serializer::Xml]
    #
    def xml_serializer
      # noinspection RubyYardReturnMatch
      serializers[:xml]
    end

    # The Hash serializer for the including class.
    #
    # @return [Api::Serializer::Hash]
    #
    def hash_serializer
      # noinspection RubyYardReturnMatch
      serializers[:hash]
    end

    # Schema definition block method.
    #
    # This method is used within the definition of a class derived from
    # Api::Record to specify its serializable data elements within the
    # block supplied to the method.
    #
    # In addition, class-specific serializers are created using these data
    # element definitions by also executing the provided block.
    #
    # @param [Array<Symbol>] serializer_types
    # @param [Proc]          block
    #
    # @return [Hash{Symbol=>Api::Serializer}]
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
          const = serializer_name(type)
          base  = serializer_base(type).constantize
          serializer = Class.new(base, &block)
          remove_const(const) if const_defined?(const)
          [key, const_set(const, serializer)]
        }.to_h
    end

  end

end

__loading_end(__FILE__)
