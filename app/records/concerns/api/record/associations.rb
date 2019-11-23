# app/records/concerns/api/record/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions used within the #schema block when it is executed in the context
# of the class which includes this module.
#
module Api::Record::Associations

  extend ActiveSupport::Concern

  module ClassMethods

    include ::Api::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    public

    # In the context of a class derived from Api::Record, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Array]                      _ignored  Additional args discarded.
    # @param [Hash]                       opt
    #
    # @return [void]
    #
    # @see Api::Serializer::Associations::ClassMethods#attribute
    # @see Api::Record::Schema::ClassMethods#schema
    #
    def attribute(name, type = nil, *_ignored, **opt)
      add_single_property(name, type, **opt)
    end

    # In the context of a class derived from Api::Record, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Array]                      _ignored  Additional args discarded.
    # @param [Hash]                       opt
    #
    # @return [void]
    #
    # @see Api::Serializer::Associations::ClassMethods#has_one
    # @see Api::Record::Schema::ClassMethods#schema
    #
    def has_one(name, type = nil, *_ignored, **opt)
      add_single_property(name, type, **opt)
    end

    # In the context of a class derived from Api::Record, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Array]                      _ignored  Additional args discarded.
    # @param [Hash]                       opt
    #
    # @return [void]
    #
    # @see Api::Serializer::Associations::ClassMethods#has_one
    # @see Api::Record::Schema::ClassMethods#schema
    #
    def has_many(name, type = nil, *_ignored, **opt)
      add_collection_property(name, type, **opt)
    end

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # Define a single data element property.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Array]                      _ignored  Additional args discarded.
    # @param [Hash]                       opt       Passed to #make_default.
    #
    def add_single_property(name, type, *_ignored, **opt)
      value = make_default(type, **opt)
      add_property(name, value)
    end

    # Define an array data element property.
    #
    # @param [Symbol] name
    # @param [Array]  _ignored        Additional arguments are discarded.
    # @param [Hash]   _opt            Options are tolerated but discarded.
    #
    # args[0]   The attribute name
    #
    def add_collection_property(name, *_ignored, **_opt)
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
    # @param [Class, String, Symbol, nil] type
    # @param [Hash, nil]                  opt   Passed to #extract_type_option
    #
    # @return [Object]  A literal value.
    # @return [Proc]    An anonymous method that generates the default value.
    #
    # Compare with:
    # @see Api::Serializer::Associations#get_type_class
    #
    def make_default(type, opt = nil)
      type = extract_type_option(opt) || type || 'String'
      type = type.to_s.classify if type.is_a?(Symbol)
      name = type.to_s
      base = name.demodulize.to_sym
      if scalar_types.include?(base)
        scalar_defaults[base]
      elsif enumeration_types.include?(base)
        enumeration_default(base)
      elsif base.to_s.start_with?('Iso')
        type = base.to_s.constantize
        ->(*)  { type.new }
      elsif !name.include?('::')
        type = "#{service_name}::Record::#{name}".constantize
        ->(*a) { type.new(nil, *a) }
      elsif name.start_with?("#{service_name}::")
        type = name.constantize unless type.is_a?(Class)
        ->(*a) { type.new(nil, *a) }
      else
        type = name.constantize unless type.is_a?(Class)
        ->(*)  { type.new }
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
    # @see Api::Record#default_data
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
