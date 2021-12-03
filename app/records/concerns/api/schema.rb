# app/records/concerns/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Values related to the details of serialization/de-serialization.
#
module Api::Schema

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

  # A table of schema property scalar types mapped to literals which are their
  # default values.
  #
  # @type [Hash{Symbol=>Any}]
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
  # @example For "has_one :the_element_name":
  #   :default =>
  #       JSON: { "the_element_name": "value" }
  #       XML:  '<the_element_name>value</the_element_name>'
  #   :underscore =>
  #       JSON: { "the_element_name": "value" }
  #       XML:  '<the_element_name>value</the_element_name>'
  #   :underscore_uppercase =>
  #       JSON: { "THE_ELEMENT_NAME": "value" }
  #       XML:  '<THE_ELEMENT_NAME>value</THE_ELEMENT_NAME>'
  #   :camelcase =>
  #       JSON: { "theElementName": "value" }
  #       XML:  '<theElementName>value</theElementName>'
  #   :full_camelcase =>
  #       JSON: { "TheElementName": "value" }
  #       XML:  '<TheElementName>value</TheElementName>'
  #   :lowercase =>
  #       JSON: { "the_element_name": "value" }
  #       XML:  '<the_element_name>value</the_element_name>'
  #   :uppercase =>
  #       JSON: { "THE_ELEMENT_NAME": "value" }
  #       XML:  '<THE_ELEMENT_NAME>value</THE_ELEMENT_NAME>'
  #
  # @example For "has_one :elementRecord":
  #   :default =>
  #       JSON: "elementRecord" : { ... }
  #       XML:  '<elementRecord>...</elementRecord>'
  #   :underscore =>
  #       JSON: "element_record" : { ... }
  #       XML:  '<element_record>...</element_record>'
  #   :underscore_uppercase =>
  #       JSON: "ELEMENT_RECORD" : { ... }
  #       XML:  '<ELEMENT_RECORD>...</ELEMENT_RECORD>'
  #   :camelcase  =>
  #       JSON: "elementRecord" : { ... }
  #       XML:  '<elementRecord>...</elementRecord>'
  #   :full_camelcase =>
  #       JSON: "ElementRecord" : { ... }
  #       XML:  '<ElementRecord>value</ElementRecord>'
  #   :lowercase =>
  #       JSON: { "elementrecord": "value" }
  #       XML:  '<elementrecord>value</elementrecord>'
  #   :uppercase =>
  #       JSON: { "ELEMENTRECORD": "value" }
  #       XML:  '<ELEMENTRECORD>value</ELEMENTRECORD>'
  #
  ELEMENT_NAMING_MODES = %i[
    default
    underscore
    underscore_uppercase
    camelcase
    full_camelcase
    lowercase
    uppercase
  ].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # service_name
  #
  # @return [String]
  #
  def service_name
    not_implemented 'to be overridden'
  end

  # A table of schema property enumeration types mapped to literals which are
  # their default values.
  #
  # @return [Hash{Symbol=>String}]
  #
  def enumeration_defaults
    not_implemented 'to be overridden'
  end

  # The enumeration types that may be given as the second argument to
  # #attribute, #has_one, or #has_many definitions.
  #
  # @return [Array<Symbol>]
  #
  def enumeration_types
    not_implemented 'to be overridden'
  end

  # enumeration_default
  #
  # @param [Symbol] type
  #
  # @return [Any]
  #
  def enumeration_default(type)
    enumeration_defaults[type]
  end

  # serializer_name
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  #
  def serializer_name(type)
    "#{type}Serializer"
  end

  # serializer_base
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  #
  def serializer_base(type)
    "#{service_name}::Api::Serializer::#{type}"
  end

  # A table of schema property scalar types mapped to literals which are their
  # default values.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def scalar_defaults
    SCALAR_DEFAULTS
  end

  # The basic types that may be given as the second argument to #attribute,
  # #has_one, or #has_many definitions.
  #
  # @type [Array<Symbol>]
  #
  def scalar_types
    SCALAR_TYPES
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Determine the format of the data.
  #
  # @param [String, Hash] data
  #
  # @return [Symbol]                  One of #SERIALIZER_TYPES
  # @return [nil]                     Otherwise
  #
  def format_of(data)
    if data.is_a?(Hash)
      :hash
    elsif data =~ /\A\s*</
      :xml
    elsif data =~ /\A\s*[{\[]/
      :json
    end
  end

  # Called to validate that *type* is in #SERIALIZER_TYPES.
  #
  # @param [Symbol] type
  #
  # @raise [SyntaxError]              If *type* is invalid.
  #
  # @return [TrueClass]
  #
  def assert_serializer_type(type)
    return true if SERIALIZER_TYPES.include?(type)
    raise RangeError, "#{type.inspect}: not in #{SERIALIZER_TYPES.inspect}"
  end

  # Indicate whether the type is a scalar (not a representer) class.
  #
  # @param [Class, String, Symbol, nil] type
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def scalar_type?(type)
    return false unless type.is_a?(Class)
    return true  if type.module_parent == Object
    return true  if type.ancestors.include?(ScalarType)
    base = type.to_s.demodulize.to_sym
    scalar_types.include?(base) || enumeration_types.include?(base)
  end

  # Ensure that attributes get a type-appropriate default (otherwise they
  # will just be *nil*).
  #
  # @param [Class, String, Symbol, nil] type
  #
  # @return [*]
  #
  def scalar_default(type)
    # noinspection RubyNilAnalysis
    type &&= type.to_s.demodulize.to_sym
    scalar_defaults[type] || enumeration_defaults[type]
  end

  # Get options that specify type.
  #
  # @param [Hash, nil] opt
  #
  # @return [Hash]
  #
  def type_options(opt)
    opt&.slice(*TYPE_OPTION_KEYS) || {}
  end

  # Get type specification from options.
  #
  # @param [Hash, nil] opt
  #
  # @return [*]
  #
  def extract_type_option(opt)
    type_options(opt).values.first
  end

  # Extract #TYPE_OPTION_KEYS from *opt* and get the type specification.
  #
  # @param [Hash] opt                 Will have #TYPE_OPTION_KEYS removed.
  #
  # @return [*]
  #
  def extract_type_option!(opt)
    return unless opt.is_a?(Hash)
    extract_type_option(opt).tap { opt.except!(*TYPE_OPTION_KEYS) }
  end

end

__loading_end(__FILE__)
