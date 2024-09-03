# app/channels/_application_cable/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Derived from Hash to provide a standardized interface for manipulating values
# that are to be transmitted back to the client.
#
class ApplicationCable::Response < Hash

  include ApplicationCable::Payload

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Response data value entries.
  #
  # @type [Hash]
  #
  # @see file://app/assets/javascripts/shared/channel-response.js *TEMPLATE*
  #
  TEMPLATE = {
    status:   nil,  # Request status.
    user:     nil,  # Requesting user.
    job_id:   nil,
    job_type: nil,  # worker or waiter
    time:     nil,  # When the response was received.
    duration: 0.0,  # Time in seconds to receive the requested results.
    late:     nil,  # Overdue by this many seconds.
    count:    nil,
    class:    nil,
    data:     nil,  # Response result data.
    data_url: nil,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [any, nil] values
  # @param [Hash]     opt
  #
  def initialize(values = nil, **opt)
    set_payload(self, values, **opt)
  end

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

  delegate :template, :default_status, to: :class

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

  # Replace :data with :data_url which references the database record where
  # this response is stored.
  #
  # It is assumed that the shape of the current instance matches #TEMPLATE and
  # that `self[:data_url]` is *nil* and that `self[:data]` is present.
  #
  # @param [Array,String,:none,nil] data_path   Location in the data hierarchy
  #                                               within #data_url_base_path
  #                                               (default 'data' unless :none)
  # @param [Hash]  opt                          Additional URL parameters.
  #
  # @return [void]
  #
  # @see file:app/assets/javascripts/channels/lookup-channel.js  *response()*
  #
  def convert_to_data_url!(data_path: nil, **opt)
    url = self[:data_url] and raise "data_url is not nil: #{url.inspect}"
    job = self[:job_id].presence or raise 'missing job_id'
    if self[:data]
      base_path = data_url_base_path.split('/')
      data_path = (Array.wrap(data_path || :data) unless data_path == :none)
      data_url  = make_path(*base_path, job, *data_path, **opt)
      update(data: nil, data_url: data_url)
    else
      Log.warn { "#{__method__}: no data: #{self.inspect}" }
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance unless *payload* is already an instance of the class
  # and there are no *opt* additions.
  #
  # @param [any, nil] payload
  # @param [Hash]     opt
  #
  # @return [ApplicationCable::Response]
  #
  def self.wrap(payload, **opt)
    # noinspection RubyMismatchedReturnType
    if payload.is_a?(self) && opt.except(*ignored_keys).blank?
      payload
    else
      new(payload, **opt)
    end
  end

  # URL path to the job result endpoint.
  #
  # @return [String]
  #
  def self.data_url_base_path
    must_be_overridden
  end

  delegate :data_url_base_path, to: :class

end

__loading_end(__FILE__)
