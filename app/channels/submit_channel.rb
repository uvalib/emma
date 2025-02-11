# app/channels/submit_channel.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bulk upload submission WebSocket channels.
#
class SubmitChannel < ApplicationCable::Channel

  include SubmissionConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @see file:javascripts/channels/submit-channel.js *DEFAULT_ACTION*
  DEFAULT_ACTION = :submission_request

  # ===========================================================================
  # :section: ApplicationCable::Channel overrides
  # ===========================================================================

  protected

  # The channel for the session.
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
    # TODO: abort any pending requests
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Receive a submission request from the client.
  #
  # @param [Hash{String=>any,nil}] payload
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *request()*
  # @see file:javascripts/channels/submit-channel.js *SubmitChannel*
  #
  def submission_request(payload)
    data = stream_recv(payload, meth: __method__)
    data = SubmissionService::BatchSubmitRequest.wrap(data)
    submission_api.make_request(data, channel: self)
  end

  # Receive a submission control request from the client.
  #
  # @param [Hash{String=>any,nil}] payload
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *request()*
  # @see file:javascripts/channels/submit-channel.js *SubmitChannel*
  #
  def submission_control(payload)
    data = stream_recv(payload, meth: __method__)
    data = SubmissionService::ControlRequest.wrap(data)
    submission_api.make_request(data, channel: self)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Invoked from another thread to push an initial response back to the client.
  #
  # @param [Hash, Array<Class>] data  Payload data
  # @param [Hash]               opt
  #
  # @option opt [Symbol]  :meth       Passed to #stream_send.
  # @option opt [Boolean] :fatal      Passed to #stream_send.
  #
  # @return [void]
  #
  def self.initial_response(data, **opt)
    str_opt = opt.extract!(:meth, :fatal)
    payload = SubmitChannel::InitialResponse.wrap(data, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **str_opt, **opt)
  end

  # Invoked from another thread to push acquired data back to the client.
  #
  # @param [Hash] data                Payload data
  # @param [Hash] opt
  #
  # @option opt [Symbol]  :meth       Passed to #stream_send.
  # @option opt [Boolean] :fatal      Passed to #stream_send.
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *response()*
  # @see file:javascripts/channels/submit-channel.js *_createResponse()*
  #
  def self.final_response(data, **opt)
    str_opt = opt.extract!(:meth, :fatal)
    payload = SubmitChannel::FinalResponse.wrap(data, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **str_opt, **opt)
  end

  # Invoked from another thread to push intermediate data back to the client.
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
  # @see file:javascripts/channels/submit-channel.js *_createResponse()*
  #
  def self.step_response(data, **opt)
    str_opt = opt.extract!(:meth, :fatal)
    payload = SubmitChannel::StepResponse.wrap(data, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **str_opt, **opt)
  end

  # Invoked from another thread to push control status back to the client.
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
  # @see file:javascripts/channels/submit-channel.js *_createResponse()*
  #
  # @note Currently unused.
  # :nocov:
  def self.control_response(data, **opt)
    str_opt = opt.extract!(:meth, :fatal)
    payload = SubmitChannel::ControlResponse.wrap(data, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **str_opt, **opt)
  end
  # :nocov:

end

__loading_end(__FILE__)
