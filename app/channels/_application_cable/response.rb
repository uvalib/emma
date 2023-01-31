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
  # @param [*]    values
  # @param [Hash] opt
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
  # @param [Array] data_path          Location in the data hierarchy.
  # @param [Hash]  opt                Additional URL parameters.
  #
  # @return [self]
  #
  # @see #data_url_base_path
  # @see file:app/assets/javascripts/channels/lookup-channel.js  *response()*
  #
  def convert_to_data_url!(data_path: nil, **opt)
    raise 'missing job_id' if (job_id = self[:job_id]).blank?
    base_path = data_url_base_path.split('/')
    data_path = data_path&.split('/') unless data_path == :none
    result =
      self.map { |k, v|
        if k == :data
          path = (data_path || [k] unless data_path == :none)
          [:data_url, make_path(*base_path, job_id, *path, **opt)]
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
  def self.wrap(payload, **opt)
    if payload.is_a?(self) && opt.except(*CHANNEL_PARAMS).blank?
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
    not_implemented 'to be overridden by the subclass'
  end

  delegate :data_url_base_path, to: :class

end

__loading_end(__FILE__)
