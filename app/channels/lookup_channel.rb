# app/channels/lookup_channel.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class LookupChannel < ApplicationCable::Channel

  include_submodules(self)

  # @see file:javascripts/channels/lookup-channel.js *DEFAULT_ACTION*
  DEFAULT_ACTION = 'lookup_request'

  # ===========================================================================
  # :section: ApplicationCable::Channel overrides
  # ===========================================================================

  protected

  # stream_name
  #
  # @return [String]
  #
  def stream_name
    @stream_name ||= super(DEFAULT_ACTION)
  end

  # Any cleanup needed when channel is unsubscribed.
  #
  # @return [void]
  #
  def unsubscribed
    super
    # TODO: abort any pending lookup requests
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  delegate :lookup_response, to: :class

  # Receive a lookup request from the client.
  #
  # @param [Hash{String=>*}] payload
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *request()*
  # @see file:javascripts/channels/lookup-channel.js *_createRequest()*
  #
  def lookup_request(payload)
    data = stream_recv(payload, meth: __method__)
    data = LookupService::Request.wrap(data)
    LookupService.request(data, channel: self)
  end

=begin
  # Push acquired data back to the client.
  #
  # @param [Hash{Symbol=>*}] payload
  # @param [Hash]            opt
  #
  # @return [void]
  #
  # @note Currently unused.
  #
  def lookup_response(payload, **opt)
    self.class.send(__method__, payload, **opt)
  end
=end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Invoked from another thread to push an initial response back to the client.
  #
  # @param [Hash{Symbol=>*}, Array<Class>] payload
  # @param [Hash]                          opt
  #
  # @return [void]
  #
  # == Implementation Notes
  # This response is intentionally small; payload size is not checked to avoid
  # masking an exception due to an unexpected condition.
  #
  def self.lookup_initial_response(payload, **opt)
    payload = LookupChannel::InitialResponse.cast(payload, **opt)
    stream_send(payload, meth: __method__, **opt)
  end

  # Invoked from another thread to push acquired data back to the client.
  #
  # @param [Hash{Symbol=>*}] payload
  # @param [Hash]            opt
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *response()*
  # @see file:javascripts/channels/lookup-channel.js *_createResponse()*
  #
  def self.lookup_response(payload, **opt)
    payload = LookupChannel::LookupResponse.cast(payload, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **opt)
  end

end

__loading_end(__FILE__)
