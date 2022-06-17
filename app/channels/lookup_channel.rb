# app/channels/lookup_channel.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class LookupChannel < ApplicationCable::Channel

  include_submodules(self)

  # ===========================================================================
  # :section: ApplicationCable::Channel overrides
  # ===========================================================================

  public

  # stream_name
  #
  # @return [String]
  #
  def stream_name
    @stream_name ||= super('lookup_request')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Receive a lookup request from the client.
  #
  # @param [Hash{String=>*}] payload
  #
  # @return [void]
  #
  # @see app/assets/javascripts/channels/lookup-channel.js *request()*
  #
  def lookup_request(payload)
    data = stream_recv(payload, meth: __method__)
    data = LookupService::Request.wrap(data)
    LookupService.request(data, channel: self)
  end

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
    payload = LookupChannel::LookupResponse.cast(payload, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **opt)
  end

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
  def self.lookup_start_response(payload, **opt)
    payload = LookupChannel::StartResponse.cast(payload, **opt)
    stream_send(payload, meth: __method__, **opt)
  end

  # Invoked from another thread to push acquired data back to the client.
  #
  # @param [Hash{Symbol=>*}] payload
  # @param [Hash]            opt
  #
  # @return [void]
  #
  def self.lookup_response(payload, **opt)
    payload = LookupChannel::LookupResponse.cast(payload, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **opt)
  end

end

__loading_end(__FILE__)
