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

    include Api::Schema

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
      # noinspection RubyMismatchedReturnType
      serializers[:json]
    end

    # The XML serializer for the including class.
    #
    # @return [Api::Serializer::Xml]
    #
    def xml_serializer
      # noinspection RubyMismatchedReturnType
      serializers[:xml]
    end

    # The Obj serializer for the including class.
    #
    # @return [Api::Serializer::Obj]
    #
    def obj_serializer
      # noinspection RubyMismatchedReturnType
      serializers[:obj]
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
    # @param [Proc]          blk
    #
    # @return [void]
    #
    # @see Api::Schema#SERIALIZER_TYPES
    # @see Api::Serializer::Associations::ClassMethods#attribute
    # @see Api::Serializer::Associations::ClassMethods#has_one
    # @see Api::Serializer::Associations::ClassMethods#has_many
    #
    def schema(*serializer_types, &blk)
      # Add record field definitions to the class itself.
      class_exec(&blk)
      # Add record field definitions to each format-specific serializer.
      @serializers =
        (serializer_types.presence || SERIALIZER_TYPES).map { |key|
          key   = key.downcase.to_sym if key.is_a?(String)
          type  = key.to_s.capitalize
          const = serializer_name(type)
          base  = serializer_base(type).constantize
          serializer = Class.new(base, &blk)
          remove_const(const) if const_defined?(const, false)
          [key, const_set(const, serializer)]
        }.to_h
    end

    # Duplicate the schema from another class.
    #
    # @param [Class<Api::Record>] other
    # @param [Hash]               opt     Passed to #all_from.
    #
    # @return [void]
    #
    def schema_from(other, **opt)
      schema do
        all_from other, **opt
      end
    end

  end

end

__loading_end(__FILE__)
