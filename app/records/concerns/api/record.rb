# app/records/concerns/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects that interact with the Bookshare API, either to be
# initialized through de-serialized data received from the API or to be
# serialized into data to be sent to the API.
#
class Api::Record

  include Model
  include ::Api::Common
  include ::Api::Schema
  include ::Api::Record::Schema
  include ::Api::Record::Associations

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [Symbol]
  attr_reader :serializer_type

  # @return [Exception, nil]
  attr_reader :exception

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Symbol]                                            format  Note [1]
  # @param [TrueClass, Hash{Symbol=>String,true}]              wrap    Note [2]
  # @param [Exception, String, TrueClass]                      error   Note [3]
  #
  # == Notes
  #
  # [1] One of Api::Schema#SERIALIZER_TYPES.  If not provided it will be
  #     determined heuristically from *data*, with #DEFAULT_SERIALIZER_TYPE as
  #     a fall-back.
  #
  # [2] A strategy for wrapping the data prior to de-serialization.  If *true*
  #     then all types are wrapped as determined by #wrap_outer.  If a Hash,
  #     then each key-value pair gives the format template to use or *true* to
  #     use the template supplied by #wrap_outer.
  #
  # [3] If an error indication is present, the instance is initialized to
  #     defaults and *data* is ignored.
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def initialize(src, format: nil, wrap: nil, error: nil, **)
    @serializer_type = format
    assert_serializer_type(@serializer_type) if @serializer_type
    @exception = error
    @exception = Api::Error.new(error) if error && !error.is_a?(Exception)
    if @exception
      @serializer_type = :hash
      initialize_attributes
    elsif src.is_a?(Api::Record)
      initialize_attributes(src)
    elsif (data = src.is_a?(Faraday::Response) ? src&.body : src).present?
      @serializer_type ||= self.format_of(data) || DEFAULT_SERIALIZER_TYPE
      wrap = wrap[@serializer_type] if wrap.is_a?(Hash)
      data = wrap_outer(data: data, template: wrap) if wrap
      deserialize(data)
    end
    @serializer_type ||= DEFAULT_SERIALIZER_TYPE
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A serializer instance of the currently-selected type.
  #
  # @param [Symbol, nil] type         Default: #serializer_type
  #
  # @return [Api::Serializer]
  #
  # @see Api::Record::Schema::ClassMethods#serializers
  #
  def serializer(type = nil)
    type ||= serializer_type
    if type == serializer_type
      @serializer ||= self.class.serializers[type].new(self)
    else
      self.class.serializers[type].new(self)
    end
  end

  # Load data elements from the supplied data.
  #
  # (If the data is a String, it must already be in the form required by the
  # serializer.)
  #
  # @param [String, Hash] data
  # @param [Symbol, nil] type         Default: #serializer_type
  #
  # @return [Api::Record]
  # @return [nil]
  #
  # @see Api::Serializer#deserialize
  #
  def deserialize(data, type = nil)
    serializer(type).deserialize(data)
  end

  # Serialize data elements to the indicated format.
  #
  # @param [Symbol, nil] type         Default: #serializer_type
  # @param [Hash]        opt          Passed to Api::Serializer#serialize
  #
  # @return [String]
  #
  # @see Api::Serializer#serialize
  #
  def serialize(type, **opt)
    serializer(type).serialize(**opt)
  end

  # Serialize the record instance into JSON format.
  #
  # @param [Hash] opt                 Passed to #serialize.
  #
  # @return [String]
  #
  # @see Api::Serializer::Json#serialize
  #
  def to_json(**opt)
    serialize(:json, **opt)
  end

  # Serialize the record instance into XML format.
  #
  # @param [Hash] opt                 Passed to #serialize.
  #
  # @return [String]
  #
  # @see Api::Serializer::Xml#serialize
  #
  def to_xml(**opt)
    serialize(:xml, **opt)
  end

  # Serialize the record instance into a Hash.
  #
  # @param [Boolean, nil] symbolize_keys
  # @param [Hash]         opt             Passed to #serialize.
  #
  # @return [String]
  #
  # @see Api::Serializer::Hash#serialize
  # @see Api::Serializer::Hash::Schema#SYMBOLIZE_KEYS
  #
  def to_hash(symbolize_keys: nil, **opt)
    opt[:symbolize_keys] = symbolize_keys unless symbolize_keys.nil?
    serialize(:hash, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Returns *nil* unless this instance is an error placeholder.
  #
  # @return [String]
  # @return [nil]                     If there is no exception.
  #
  def error_message
    exception&.message
  end

  # Indicate whether this is an instance created as part of a placeholder
  # generated due to a failure to acquire valid data from the source.
  #
  def error?
    exception.present?
  end

  # Indicate whether this is a valid data instance.
  #
  def valid?
    !error?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default data used to initialize an instance.
  #
  # @return [Hash{Symbol=>Any}]
  #
  # @see Api::Record::Associations#property_defaults
  #
  def default_data
    self.class.property_defaults
  end

  # The field definitions in the schema for this record.
  #
  # @return [Array<Hash>]
  #
  def field_definitions
    serializer.representable_map.map do |field|
      {
        name:       field[:name],
        collection: field[:collection],
        type:       (field[:class] || field[:type]),
      }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Update record fields from a hash of values.
  #
  # @param [Hash] hash
  #
  # @return [self]
  #
  def update(hash)
    hash.each_pair { |k, v| try("#{k}=", v) } if hash.present?
    self
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # The fields defined in the schema for this record.
  #
  # @return [Array<Symbol>]
  #
  def field_names
    field_definitions.map { |field| field[:name].to_sym }.sort
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # inspect
  #
  # @return [String]
  #
  def inspect
    items =
      instance_variables.map do |variable|
        '%s=%s' % [variable, instance_variable_get(variable).inspect]
      end
    "#<%s:\n%s\n>" % [self.class, items.join(",\n")]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Directly assign schema attributes.
  #
  # @param [Api::Record, Hash, nil] data  Default: #default_data
  #
  # @return [void]
  #
  # == Usage Notes
  # With no (or nil) argument, this initializes all fields from #default_data.
  # (This is useful in situations where you want all fields displayable whether
  # they were initialized with data or not).
  #
  # If *data* is provided, then *only* those fields will be initialized.
  # (This is useful where you want fields that were not initialized with data
  # to return *nil*.)
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def initialize_attributes(data = nil)
    data = data.fields if data.is_a?(Api::Record)
    data = data.symbolize_keys.slice(*default_data.keys) if data.is_a?(Hash)
    (data || default_data).each_pair do |attr, value|
      value = value.call(error: exception) if value.is_a?(Proc)
      value = value.new                    if value.is_a?(Class)
      value = value.value                  if value.is_a?(ScalarType)
      send(:"#{attr}=", value)
    end
  end

  # wrap_outer
  #
  # @param [Hash, String] data
  # @param [Symbol]       fmt         Default: `#serializer_type`
  # @param [String]       name        Element name (default based on class).
  # @param [String]       template
  #
  # @return [Hash, String]            Same type as *data*.
  #
  def wrap_outer(data:, fmt: nil, name: nil, template: nil)
    name ||= self.class.name.demodulize.to_s.camelcase(:lower)
    return { name => data } if data.is_a?(Hash)
    template = nil unless template.is_a?(String)
    case (fmt || serializer_type)
      when :xml
        template ||= "<#{name}>%{data}</#{name}>"
        _, prolog, body = data.partition(/^<\?.*?\?>\n?/)
        if body.present?
          "#{prolog}#{template}" % { data: body }
        else
          template % { data: data }
        end
      when :json
        template ||= %Q("#{name}":{%{data}})
        template % { data: data }
      else
        data
    end
  end

end

__loading_end(__FILE__)
