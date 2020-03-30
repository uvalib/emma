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
  # @param [Faraday::Response, Hash, String, nil] data
  # @param [Hash]                                 opt
  #
  # @option opt [Symbol]                               :format  Note [1]
  # @option opt [TrueClass, Hash{Symbol=>String,true}] :wrap    Note [2]
  # @option opt [Exception, String, TrueClass]         :error   Note [3]
  #
  # == Notes
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
  def initialize(data, opt = nil)
    opt ||= {}
    @exception = error = opt[:error]
    @exception = Api::Error.new(error) if error && !error.is_a?(Exception)
    if @exception
      @serializer_type = :hash
      initialize_attributes
    else
      data = data.body.presence if data.is_a?(Faraday::Response)
      @serializer_type = opt[:format] || self.format_of(data)
      assert_serializer_type(@serializer_type) if @serializer_type
      @serializer_type ||= DEFAULT_SERIALIZER_TYPE
      fmt_wrap = opt[:wrap]
      fmt_wrap = fmt_wrap[@serializer_type] if fmt_wrap.is_a?(Hash)
      data = wrap_outer(data: data, template: fmt_wrap) if fmt_wrap
      # noinspection RubyYardParamTypeMatch
      deserialize(data)
    end
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

  # Default data used to initialize an error instance.
  #
  # @return [Hash{Symbol=>BasicObject}]
  #
  # @see Api::Record::Associations#property_defaults
  #
  def default_data
    self.class.property_defaults.deep_dup
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
    (hash || {}).each_pair { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
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
  # This method overrides:
  # @see Model#field_names
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
  # This method overrides
  # @see Object#inspect
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
  # @param [Hash, nil] data           Default: #default_data
  #
  # @return [Hash{Symbol=>BasicObject}]
  #
  # == Usage Notes
  # This is only intended for use in the initialization of an error instance.
  #
  def initialize_attributes(data = nil)
    (data || default_data).each_pair do |attr, value|
      # noinspection RubyCaseWithoutElseBlockInspection
      case value
        when Class then value = value.new
        when Proc  then value = value.call(error: exception)
      end
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
    name ||= self.class.name.demodulize.camelcase(:lower)
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
