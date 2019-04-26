# app/models/concerns/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Api

  # Values related to the details of serialization/de-serialization.
  #
  module Schema

    # The implemented serializer types.
    #
    # @type [Array<Symbol>]
    #
    SERIALIZER_TYPES = %i[json xml hash].freeze

    # The default serializer type.
    #
    # @type [Symbol]
    #
    DEFAULT_SERIALIZER_TYPE = :json

    # The options to #attribute, #has_one, or #has_many definitions which
    # indicate the specification of a type for the schema property or (in the
    # case of #has_many) its constituent parts.
    #
    # @type [Array<Symbol>]
    #
    TYPE_OPTION_KEYS = %i[type extend decorator].freeze

    # A table of schema property scalar types mapped to literals which are
    # their default values.
    #
    # @type [Hash{Symbol=>Object}]
    #
    SCALAR_DEFAULTS = {
      '':          '',
      Boolean:     false,
      Date:        Date.new,
      DateTime:    DateTime.new,
      FalseClass:  false,
      Float:       0.0,
      Integer:     0,
      Numeric:     0,
      String:      '',
      Symbol:      :'',
      TrueClass:   true,
    }.freeze

    # The basic types that may be given as the second argument to #attribute,
    # #has_one, or #has_many definitions.
    #
    # @type [Array<Symbol>]
    #
    SCALAR_TYPES = SCALAR_DEFAULTS.keys.freeze

    # Possible relationships between a schema property defined by 'attribute',
    # 'has_one' or 'has_many' and the name of the serialized data element.
    #
    # @type [Array<Symbol>]
    #
    # @example For "attribute :the_attribute_name":
    #   :default =>
    #       JSON: { "the_attribute_name": "value" }
    #       XML:  '<the_attribute_name>value</the_attribute_name>'
    #   :underscore =>
    #       JSON: { "the_attribute_name": "value" }
    #       XML:  '<the_attribute_name>value</the_attribute_name>'
    #   :camelcase =>
    #       JSON: { "theAttributeName": "value" }
    #       XML:  '<theAttributeName>value</theAttributeName>'
    #   :full_camelcase =>
    #       JSON: { "TheAttributeName": "value" }
    #       XML:  '<TheAttributeName>value</TheAttributeName>'
    #
    # @example For "has_one :elementRecord":
    #   :default =>
    #       JSON: "elementRecord" : { ... }
    #       XML:  '<elementRecord>...</elementRecord>'
    #   :underscore =>
    #       JSON: "element_record" : { ... }
    #       XML:  '<element_record>...</element_record>'
    #   :camelcase  =>
    #       JSON: "elementRecord" : { ... }
    #       XML:  '<elementRecord>...</elementRecord>'
    #   :full_camelcase =>
    #       JSON: "ElementRecord" : { ... }
    #       XML:  '<ElementRecord>value</ElementRecord>'
    #
    ELEMENT_NAMING_MODES =
      %i[default underscore camelcase full_camelcase].freeze

    # The selected schema property naming mode.
    #
    # @type [Symbol]
    #
    ELEMENT_NAMING_MODE = :camelcase

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Determine the format of the data.
    #
    # @param [String, Hash] data
    #
    # @return [Symbol]                One of Api::Schema#SERIALIZER_TYPES
    # @return [nil]                   Otherwise
    #
    def format_of(data)
      if data.is_a?(Hash)
        :hash
      elsif data =~ /^\s*</
        :xml
      elsif data =~ /^\s*[{\[]/
        :json
      end
    end

    # Called to validate that *type* is in #SERIALIZER_TYPES.
    #
    # @param [Symbol] type
    #
    # @raise [SyntaxError]            If *type* is invalid.
    #
    def assert_serializer_type(type)
      return if SERIALIZER_TYPES.include?(type)
      raise SyntaxError, "#{type.inspect}: not in #{SERIALIZER_TYPES.inspect}"
    end

    # Indicate whether the type is a scalar (not a representer) class.
    #
    # @param [Class, nil] type
    #
    # @return [Symbol]
    #
    def scalar_type?(type)
      name = type.to_s.demodulize.to_sym
      SCALAR_TYPES.include?(name) || (type.parent == Object)
    end

    # Transform *name* into the form indicated by the given naming mode.
    #
    # @param [String, Symbol] name
    # @param [Symbol, nil]    mode
    #
    # @return [String]
    #
    def element_name(name, mode = nil)
      name = name.to_s
      case mode
        when :underscore     then name = name.underscore
        when :camelcase      then name = name.camelcase(:lower)
        when :full_camelcase then name = name.camelcase(:upper)
      end
      name
    end

  end

end

__loading_end(__FILE__)
