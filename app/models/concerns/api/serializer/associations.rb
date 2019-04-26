# app/models/concerns/api/serializer/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/serializer'

# Definitions used within the #schema block when it is executed in the context
# of a serializer class definition.
#
module Api::Serializer::Associations

  extend ActiveSupport::Concern

  # The maximum number of elements within a collection.
  #
  # @type [Integer]
  #
  # == Usage Notes
  # This is not currently an enforced maximum -- it's only used to distinguish
  # between #has_one and #has_many.
  #
  MAX_HAS_MANY_COUNT = 9999

  module ClassMethods

    include Api
    include Api::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    public

    # Simulate ActiveRecord::Attributes#attribute to define a schema property
    # that is handled as an attribute.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Hash, nil]                  opt
    #
    # @return [void]
    #
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Api::Record::Base; schema { attribute :elem }; end  -->
    #     "XXX" : { "elem" : "value" }
    #
    # @example XML:
    #   class XXX < Api::Record::Base; schema { attribute :elem }; end  -->
    #     <XXX elem="value"></XXX>
    #
    def attribute(name, type = nil, **opt)
      # If the type is missing or explicitly "String" then *type* will be
      # returned as *nil*.
      type = extract_type_option!(opt) || type
      type = get_type(nil, type)
      opt[:type] = type if type

      # Ensure that attributes get a type-appropriate default (otherwise they
      # will just be *nil*).
      opt[:default] ||= SCALAR_DEFAULTS[type.to_s.demodulize.to_sym]

      prepare_attribute!(type, opt)

      property(name, opt)
    end

    # Simulate ActiveRecord::Associations#has_one to define a schema property
    # that is handled as a single element.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Hash, nil]                  opt
    #
    # @return [void]
    #
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Api::Record::Base; schema { has_one :elem }; end  -->
    #     "XXX" : { "elem" : "value" }
    #
    # @example XML:
    #   class XXX < Api::Record::Base; schema { attribute :elem }; end  -->
    #     <XXX><elem>value</elem></XXX>
    #
    def has_one(name, type = nil, **opt, &block)
      type = extract_type_option!(opt) || type
      type = get_type(name, type)
      if scalar_type?(type)
        opt[:attribute] = false
        attribute(name, type, opt)
        Log.warn("#{__method__}: block not processed") if block_given?
      else
        has_many(name, type, 1, opt, &block)
      end
    end

    # Simulate ActiveRecord::Associations#has_many to define a schema property
    # that is handled as a collection.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Numeric, nil]               count
    # @param [Hash, nil]                  opt
    #
    # @return [void]
    #
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Api::Record::Base; schema { has_many :elem }; end  -->
    #     "XXX" : { "elem" : [...] }
    #
    # @example XML (WRAP_COLLECTIONS = true)
    #   class XXX < Api::Record::Base; schema { has_many :elem }; end  -->
    #     <XXX><elems><elem>...</elem>...<elem>...</elem></elems></XXX>
    #
    # @example XML (WRAP_COLLECTIONS = false)
    #   class XXX < Api::Record::Base; schema { has_many :elem }; end  -->
    #     <XXX><elem>...</elem>...<elem>...</elem></XXX>
    #
    def has_many(name, type = nil, count = MAX_HAS_MANY_COUNT, **opt, &block)
      type = extract_type_option!(opt) || type
      type = get_type(name, type) || Axiom::Types::String

      if scalar_type?(type)
        opt[:type]      = type
      else
        opt[:class]     = type
        opt[:decorator] = decorator_class(type)
      end

      unless count == 1
        opt[:collection] = true
        prepare_collection!(name, type, opt)
      end

      property(name, opt, &block)
    end

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # Extract #TYPE_OPTION_KEYS.
    #
    # @param [Hash] opt               May be modified.
    #
    # @return [Object, nil]
    #
    def extract_type_option!(opt)
      type_options = opt&.slice(*TYPE_OPTION_KEYS) || {}
      opt.replace(opt.except(*type_options.keys)) if type_options.present?
      type_options.values.first
    end

    # Determine the class to be associated with a data element.
    #
    # @param [Symbol]                     property_name
    # @param [Class, String, Symbol, nil] type
    #
    # @return [Class]
    # @return [nil]                   If implicitly or explicitly String.
    #
    def get_type(property_name, type)
      type ||= property_name
      type = type.to_s.classify if type.is_a?(Symbol)
      name = type.to_s
      base = name.demodulize.to_sym
      base = :Boolean if %i[TrueClass FalseClass].include?(base)
      if base.blank? || (base == :String)
        type = nil
      elsif SCALAR_TYPES.include?(base)
        type = "Axiom::Types::#{base}"
      elsif !name.include?('::')
        type = "Api::#{name}"
      end
      type.is_a?(String) ? type.constantize : type
    end

    # decorator_class
    #
    # @param [Class, String] record_class
    #
    # @return [Proc]
    #
    # @see Api::Serializer::Base#serializer_type
    #
    def decorator_class(record_class)
      ->(*) {
        format = serializer_type.to_s.capitalize
        "#{record_class}::#{format}Serializer".constantize
      }
    end

    # Format-specific operations for #attribute data elements.
    #
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  _options
    #
    # @return [void]
    #
    def prepare_attribute!(_element, _options)
    end

    # Format-specific operations for #has_many data elements.
    #
    # @param [String, Symbol]        _wrapper
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  _options
    #
    # @return [void]
    #
    def prepare_collection!(_wrapper, _element, _options)
    end

  end

end

__loading_end(__FILE__)
