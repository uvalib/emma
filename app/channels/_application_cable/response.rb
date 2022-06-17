# app/channels/_application_cable/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Derived from Hash to provide a standardized interface for manipulating values
# that are to be transmitted back to the client.
#
class ApplicationCable::Response < Hash

  TEMPLATE = {
    status: nil,
    user:   nil,
    time:   nil,
    job_id: nil,
    class:  nil,
    data:   nil,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [*]    values
  # @param [Hash] opt
  #
  def initialize(values = nil, **opt)
    if values.is_a?(self.class)
      update(values)
    else
      update(template)
      update(normalize(values)) if values.present?
    end
    update(normalize(opt)) if opt.present?
    self[:time]  ||= Time.now
    self[:class] ||= self.class.name
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @private
  # @type [Array<Symbol>]
  CHANNEL_PARAMS = %i[stream_id stream_name meth].freeze

  # Hash keys which should not be included with the data stored in the class
  # instance.
  #
  # @type [Array<Symbol>]
  #
  def ignored_keys
    CHANNEL_PARAMS
  end

  # normalize
  #
  # @param [*] value
  #
  # @return [Hash{Symbol=>*}]
  #
  # == Implementation Notes
  # Message classes based on a Hash data item require #to_h in order to avoid
  # propagating out-of-band data.
  #
  def normalize(value)
    return {}    if value.nil?
    return value if value.is_a?(self.class)
    value = { data: value } unless value.is_a?(Hash)
    value = value.deep_symbolize_keys
    value.except!(*ignored_keys)
    value.deep_transform_values! { |v| v.try(:to_h) || v }
  end

  # ===========================================================================
  # :section: Hash overrides
  # ===========================================================================

  public

  def to_h
    compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL path to the job result lookup endpoint.
  # TODO: real location for data_url! ... ?
  #
  # @type [String]
  #
  DEF_BASE_PATH = 'tool/lookup_result'

  # Replace :data with :data_url which references the database record where
  # this response is stored.
  #
  # @param [String] base_path   URL path to the job result lookup endpoint.
  # @param [Array]  data_path   Location in the data hierarchy.
  # @param [Hash]   opt         Additional URL parameters.
  #
  # @return [self]
  #
  # @see file:app/assets/javascripts/channels/lookup-channel.js  *response*
  #
  def convert_to_data_url!(base_path: DEF_BASE_PATH, data_path: nil, **opt)
    raise "#{__method__} requires :job_id" if (job_id = self[:job_id]).blank?
    base_path = base_path&.split('/') || []
    data_path = data_path&.split('/') unless data_path == :none
    result =
      self.map { |k, v|
        if k == :data
          data_path = (data_path || k unless data_path == :none)
          [:data_url, make_path(base_path, job_id, data_path, **opt)]
        else
          [k, v]
        end
      }.to_h
    replace(result)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance unless *payload* is already an instance of the class
  # and there are no *opt* additions.
  #
  # @param [*]    payload
  # @param [Hash] opt
  #
  # @return [ApplicationCable::Response]
  #
  def self.cast(payload, **opt)
    if payload.is_a?(self) && opt.except(*CHANNEL_PARAMS).blank?
      payload
    else
      new(payload, **opt)
    end
  end

  # template
  #
  # @return [Hash{Symbol=>*}]
  #
  def self.template
    TEMPLATE
  end

  delegate :template, to: :class

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Define a set of fields to be associated with instance of the class in the
  # preferred order.
  #
  # @param [Hash, Array, nil] items
  #
  # @return [Hash{Symbol=>*}]
  #
  # @yield Alternate mechanism for providing *items*.
  # @yieldreturn [Hash, Array]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def self.make_response_template(items = nil)
    items ||= yield
    own_template =
      case items
        when Hash  then items.symbolize_keys
        when Array then items.map { |k| [k.to_sym, nil] }.to_h
        else            Log.error("#{self}.#{__method__}: #{items.inspect}")
      end
    # noinspection RailsParamDefResolve
    unless application_deployed? || (parent = superclass.try(:template)).nil?
      missing = ((parent.keys - own_template.keys).presence if own_template)
      raise "#{self}::TEMPLATE missing keys: #{missing.inspect}" if missing
    end
    own_template
  end

end

__loading_end(__FILE__)
