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

    include Api::Serializer::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    public

    # Simulate ActiveRecord::Attributes#attribute to define a schema property
    # that is handled as an attribute.
    #
    # @param [Symbol] name
    # @param [Array]  args
    # @param [Hash]   opt
    #
    # @return [void]
    #
    # @see Declarative::Schema::DSL#property
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Variations
    #
    # @overload has_one(name, **opt, &block)
    #   @param [Symbol]                name
    #   @param [Hash]                  opt
    #
    # @overload has_one(name, type, *_, **opt)
    #   @param [Symbol]                name
    #   @param [Class, String, Symbol] type
    #   @param [Array]                 _      Additional arguments are ignored.
    #   @param [Hash]                  opt
    #
    # == Examples
    #
    # @example JSON:
    #   class XXX < Api::Record; schema { attribute :elem }; end  -->
    #     "XXX" : { "elem" : "value" }
    #
    # @example XML:
    #   class XXX < Api::Record; schema { attribute :elem }; end  -->
    #     <XXX elem="value"></XXX>
    #
    def attribute(name, *args, **opt)
      type = get_type_class(args.shift, **opt)
      opt[:type]      = type
      opt[:default] ||= scalar_default(type)
      prepare_attribute!(name, type, opt)
      property(name, opt)
    end

    # Simulate ActiveRecord::Associations#has_one to define a schema property
    # that is handled as a single element.
    #
    # @param [Symbol] name
    # @param [Array]  args
    # @param [Hash]   opt
    # @param [Proc]   block           Passed to #property.
    #
    # @return [void]
    #
    # @see Declarative::Schema::DSL#property
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Variations
    #
    # @overload has_one(name, **opt, &block)
    #   @param [Symbol]                name
    #   @param [Hash]                  opt
    #   @param [Proc]                  block
    #
    # @overload has_one(name, type, *_, **opt)
    #   @param [Symbol]                name
    #   @param [Class, String, Symbol] type
    #   @param [Array]                 _      Additional arguments are ignored.
    #   @param [Hash]                  opt
    #   @param [Proc]                  block
    #
    # == Examples
    #
    # @example JSON:
    #   class XXX < Api::Record; schema { has_one :elem }; end  -->
    #     "XXX" : { "elem" : "value" }
    #
    # @example XML:
    #   class XXX < Api::Record; schema { has_one :elem }; end  -->
    #     <XXX><elem>value</elem></XXX>
    #
    def has_one(name, *args, **opt, &block)
      type = get_type_class(args.shift, **opt)
      if scalar_type?(type)
        opt[:type]      = type
        opt[:default] ||= scalar_default(type)
        Log.warn { "#{__method__}: block ignored" } if block
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
    # @param [Symbol] name
    # @param [Array]  args
    # @param [Hash]   opt
    # @param [Proc]   block           Passed to #property.
    #
    # @return [void]
    #
    # @see Declarative::Schema::DSL#property
    # @see Api::Record::Schema::ClassMethods#schema
    #
    # == Variations
    #
    # @overload has_many(name, **opt, &block)
    #   @param [Symbol]                name
    #   @param [Hash]                  opt
    #   @param [Proc]                  block
    #
    # @overload has_many(name, type, *_, **opt)
    #   @param [Symbol]                name
    #   @param [Class, String, Symbol] type
    #   @param [Array]                 _      Additional arguments are ignored.
    #   @param [Hash]                  opt
    #   @param [Proc]                  block
    #
    # == Examples
    #
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
    def has_many(name, *args, **opt, &block)
      type = get_type_class(args.shift, **opt)
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
    # @param [Hash]                       opt   Passed to #extract_type_option!
    #
    # @raise [NameError]              If *type* is invalid.
    #
    # @return [Class]
    #
    # Compare with:
    # Api::Record::Associations#make_default
    #
    #--
    # noinspection RubyMismatchedReturnType
    #++
    def get_type_class(type, **opt)
      type   = extract_type_option!(opt) || type || String
      type   = type.to_s.classify if type.is_a?(Symbol)
      name   = type.to_s
      base   = name.demodulize.to_sym
      base   = :Boolean if %i[TrueClass FalseClass].include?(base)
      scalar = "Axiom::Types::#{base}"
      record = "#{service_name}::Record::#{name}"
      (scalar.safe_constantize    if scalar_types.include?(base))      ||
      (base.to_s.safe_constantize if enumeration_types.include?(base)) ||
      (base.to_s.safe_constantize if base.to_s.start_with?('Iso'))     ||
      (record.safe_constantize    unless name.include?('::'))          ||
      (type.is_a?(Class) ? type : name.constantize)
    end

    # decorator_class
    #
    # @param [Class, String, Symbol] record_class
    #
    # @raise [NameError]              If *record_class* is not valid.
    #
    # @return [Proc]
    #
    # @see Api::Serializer#serializer_type
    #
    def decorator_class(record_class)
      ->(*_args, **opt) {
        current = opt.dig(:options, :doc).class.to_s
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
      options[:attribute]  = true if %w(href rel).include?(name.to_s)
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
      options[:render_nil] = render_nil?
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
