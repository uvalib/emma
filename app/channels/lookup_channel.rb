# app/channels/lookup_channel.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class LookupChannel < ApplicationCable::Channel

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @see file:javascripts/channels/lookup-channel.js *DEFAULT_ACTION*
  DEFAULT_ACTION = :lookup_request

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

  # Receive a lookup request from the client.
  #
  # @param [Hash{String=>any,nil}] payload
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *request()*
  # @see file:javascripts/channels/lookup-channel.js *_createRequest()*
  #
  def lookup_request(payload)
    data = stream_recv(payload, meth: __method__)
    data = LookupService::Request.wrap(data)
    LookupService.make_request(data, channel: self)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Invoked from another thread to push an initial response back to the client.
  #
  # @param [Hash, Array<Class>] data   Payload data.
  # @param [Hash]               opt
  #
  # @option opt [Symbol]  :meth       Passed to #stream_send.
  # @option opt [Boolean] :fatal      Passed to #stream_send.
  #
  # @return [void]
  #
  # === Implementation Notes
  # This response is intentionally small; payload size is not checked to avoid
  # masking an exception due to an unexpected condition.
  #
  def self.initial_response(data, **opt)
    str_opt = opt.extract!(:meth, :fatal)
    payload = LookupChannel::InitialResponse.wrap(data, **opt)
    stream_send(payload, meth: __method__, **str_opt, **opt)
  end

  # Invoked from another thread to push acquired data back to the client.
  #
  # @param [Hash] data                Payload data.
  # @param [Hash] opt
  #
  # @option opt [Symbol]  :meth       Passed to #stream_send.
  # @option opt [Boolean] :fatal      Passed to #stream_send.
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *response()*
  # @see file:javascripts/channels/lookup-channel.js *_createResponse()*
  #
  def self.lookup_response(data, **opt)
    str_opt = opt.extract!(:meth, :fatal)
    payload = LookupChannel::LookupResponse.wrap(data, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **str_opt, **opt)
  end

end

__loading_end(__FILE__)
