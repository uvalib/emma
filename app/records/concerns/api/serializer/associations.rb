# app/records/concerns/api/serializer/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions used within the #schema block when it is executed in the context
# of a serializer class definition.
#
module Api::Serializer::Associations

  extend ActiveSupport::Concern

  module ClassMethods

    include ::Api::Serializer::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    public

    # Simulate ActiveRecord::Attributes#attribute to define a schema property
    # that is handled as an attribute.
    #
    # @param [Symbol]                name
    # @param [Class, String, Symbol] type
    # @param [Hash]                  opt
    #
    # @return [void]
    #
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Api::Record; schema { attribute :elem }; end  -->
    #     "XXX" : { "elem" : "value" }
    #
    # @example XML:
    #   class XXX < Api::Record; schema { attribute :elem }; end  -->
    #     <XXX elem="value"></XXX>
    #
    def attribute(name, type, **opt)
      type = get_type_class(type, opt)
      opt[:type]      = type
      opt[:default] ||= scalar_default(type)
      prepare_attribute!(name, type, opt)
      property(name, opt)
    end

    # Simulate ActiveRecord::Associations#has_one to define a schema property
    # that is handled as a single element.
    #
    # @param [Symbol]                name
    # @param [Class, String, Symbol] type
    # @param [Hash]                  opt
    # @param [Proc]                  block   Passed to #property.
    #
    # @return [void]
    #
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Api::Record; schema { has_one :elem }; end  -->
    #     "XXX" : { "elem" : "value" }
    #
    # @example XML:
    #   class XXX < Api::Record; schema { attribute :elem }; end  -->
    #     <XXX><elem>value</elem></XXX>
    #
    def has_one(name, type, **opt, &block)
      type = get_type_class(type, opt)
      if scalar_type?(type)
        opt[:type]      = type
        opt[:default] ||= scalar_default(type)
        Log.warn { "#{__method__}: block not processed" } if block_given?
      else
        opt[:class]     = type
        opt[:decorator] = decorator_class(type)
      end
      prepare_one!(name, type, opt)
      property(name, opt, &block)
    end

    # Simulate ActiveRecord::Associations#has_many to define a schema property
    # that is handled as a collection.
    #
    # @param [Symbol]                name
    # @param [Class, String, Symbol] type
    # @param [Hash]                  opt
    # @param [Proc]                  block   Passed to #property.
    #
    # @return [void]
    #
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Api::Record; schema { has_many :elem }; end  -->
    #     "XXX" : { "elem" : [...] }
    #
    # @example XML (WRAP_COLLECTIONS = true)
    #   class XXX < Api::Record; schema { has_many :elem }; end  -->
    #     <XXX><elems><elem>...</elem>...<elem>...</elem></elems></XXX>
    #
    # @example XML (WRAP_COLLECTIONS = false)
    #   class XXX < Api::Record; schema { has_many :elem }; end  -->
    #     <XXX><elem>...</elem>...<elem>...</elem></XXX>
    #
    def has_many(name, type, **opt, &block)
      type = get_type_class(type, opt)
      if scalar_type?(type)
        opt[:type]      = type
      else
        opt[:class]     = type
        opt[:decorator] = decorator_class(type)
      end
      prepare_collection!(name, type, opt)
      property(name, opt, &block)
    end

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # Determine the class to be associated with a data element.
    #
    # @param [Class, String, Symbol, nil] type
    # @param [Hash, nil]                  opt   Passed to #extract_type_option!
    #
    # @return [Class]
    #
    # Compare with:
    # @see Api::Record::Associations#make_default
    #
    def get_type_class(type, opt = nil)
      type = extract_type_option!(opt) || type || 'String'
      type = type.to_s.classify if type.is_a?(Symbol)
      name = type.to_s
      base = name.demodulize.to_sym
      base = :Boolean if %i[TrueClass FalseClass].include?(base)
      if scalar_types.include?(base)
        type = "Axiom::Types::#{base}"
      elsif enumeration_types.include?(base)
        type = base.to_s
      elsif base.to_s.start_with?('Iso')
        type = base.to_s
      elsif !name.include?('::')
        type = "#{service_name}::Record::#{name}"
      end
      # noinspection RubyYardReturnMatch
      type.is_a?(Class) ? type : name.constantize
    end

    # decorator_class
    #
    # @param [Class, String, Symbol] record_class
    #
    # @return [Proc]
    #
    # @see Api::Serializer#serializer_type
    #
    def decorator_class(record_class)
      ->(*args) {
        current = args.first.dig(:options, :doc).class.to_s
        format  = current.match?(/xml/i) ? :xml : serializer.serializer_type
        format  = format.to_s.capitalize
        "#{record_class}::#{serializer_name(format)}".constantize
      }
    end

    # Format-specific operations for #attribute data elements.
    #
    # @param [String, Symbol]        name
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  options
    #
    # @return [void]
    #
    def prepare_attribute!(name, _element, options)
      options[:attribute]  = true if %i[href rel].include?(name)
      options[:render_nil] = render_nil?
    end

    # Format-specific operations for #has_one data elements.
    #
    # @param [String, Symbol]        _name
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  options
    #
    # @return [void]
    #
    def prepare_one!(_name, _element, options)
      options.delete(:collection)
    end

    # Format-specific operations for #has_many data elements.
    #
    # @param [String, Symbol]        _wrapper
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  options
    #
    # @return [void]
    #
    def prepare_collection!(_wrapper, _element, options)
      options[:collection]   = true
      options[:render_empty] = render_empty?
    end

  end

end

__loading_end(__FILE__)
