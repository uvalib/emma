# app/models/concerns/api/record/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Definitions used within the #schema block when it is executed in the context
# of the class which includes this module.
#
module Api::Record::Associations

  extend ActiveSupport::Concern

  module ClassMethods

    include Api
    include Api::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    public

    # In the context of a class derived from Api::Record::Base, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @param [Array]     args
    # @param [Hash, nil] opt
    #
    # @return [void]
    #
    # @see Api::Serializer::Associations::ClassMethods#attribute
    # @see Api::Record::Schema::ClassMethods#schema
    #
    def attribute(*args, **opt)
      add_single_property(*args, **opt)
    end

    # In the context of a class derived from Api::Record::Base, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @param [Array]     args
    # @param [Hash, nil] opt
    #
    # @return [void]
    #
    # @see Api::Serializer::Associations::ClassMethods#has_one
    # @see Api::Record::Schema::ClassMethods#schema
    #
    def has_one(*args, **opt)
      add_single_property(*args, **opt)
    end

    # In the context of a class derived from Api::Record::Base, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @param [Array]     args
    # @param [Hash, nil] opt
    #
    # @return [void]
    #
    # @see Api::Serializer::Associations::ClassMethods#has_one
    # @see Api::Record::Schema::ClassMethods#schema
    #
    def has_many(*args, **opt)
      add_collection_property(*args, **opt)
    end

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    private

    # Define a single data element property.
    #
    # @param [Array]     args
    # @param [Hash, nil] opt
    #
    # args[0]   The attribute name
    # args[1]   The attribute type (if given).
    #
    def add_single_property(*args, **opt)
      name  = args.shift
      type  = args.shift
      value = make_default(name, type, opt)
      add_property(name, value)
    end

    # Define an array data element property.
    #
    # @param [Array]     args
    # @param [Hash, nil] _opt        Unused
    #
    # args[0]   The attribute name
    #
    def add_collection_property(*args, **_opt)
      name  = args.first
      value = []
      add_property(name, value)
    end

    # Store the property name and default value and create the property via
    # Module#attr_accessor.
    #
    # @param [Symbol, String] name
    # @param [Object, nil]    default
    #
    # @return [void]
    #
    # @see #add_property_default
    #
    def add_property(name, default = nil)
      self.add_property_default(name, default)
      attr_accessor(name)
    end

    # Get a default for a schema property data element.
    #
    # @param [Symbol]                     property_name
    # @param [Class, String, Symbol, nil] type
    # @param [Hash, nil]                  opt
    #
    # @return [Object]  A literal value.
    # @return [Proc]    An anonymous method that generates the default value.
    #
    def make_default(property_name, type = nil, **opt)
      type = opt.slice(*TYPE_OPTION_KEYS).values.first || type || property_name
      type = type.to_s.classify if type.is_a?(Symbol)
      name = type.to_s.presence || 'String'
      base = name.demodulize.to_sym
      base = :FalseClass if %i[Boolean TrueClass].include?(base)
      if SCALAR_TYPES.include?(base)
        SCALAR_DEFAULTS[base]
      elsif ENUMERATION_TYPES.include?(base)
        ENUMERATION_DEFAULTS[base]
      elsif name.start_with?('Api::')
        type = type.constantize unless type.is_a?(Class)
        ->(**opt) { type.new(nil, opt) }
      elsif !name.include?('::')
        type = "Api::#{name}".constantize
        ->(**opt) { type.new(nil, opt) }
      else
        type = type.constantize unless type.is_a?(Class)
        ->(*) { type.new }
      end
    end

    # =========================================================================
    # :section: Property defaults
    # =========================================================================

    public

    # A mapping of schema property names to their default values for use in
    # constructing an error instance.
    #
    # Hash values may be literal instances of scalar types, or they may be
    # classes or procs.
    #
    # @type [Hash{Symbol=>BasicObject}]
    #
    # @see Api::Record::Base#default_data
    #
    def property_defaults
      @property_defaults ||= {}
    end

    # =========================================================================
    # :section: Property defaults
    # =========================================================================

    protected

    # Set the default value for a property.
    #
    # @param [Symbol, String] name
    # @param [BasicObject]    value
    #
    # @return [Hash{Symbol=>BasicObject}]
    #
    def add_property_default(name, value)
      property_defaults[name.to_s.to_sym] = value.freeze
    end

  end

end

__loading_end(__FILE__)
