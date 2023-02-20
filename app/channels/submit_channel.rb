# app/channels/submit_channel.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

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
    # TODO: abort any pending requests
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Receive a submission request from the client.
  #
  # @param [Hash{String=>*}] payload
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
  # @param [Hash{String=>*}] payload
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
  # @param [Hash{Symbol=>*}, Array<Class>] payload
  # @param [Boolean, nil]                  no_raise   Passed to #stream_send.
  # @param [Hash]                          opt
  #
  # @return [void]
  #
  def self.initial_response(payload, no_raise: nil, **opt)
    payload = SubmitChannel::InitialResponse.wrap(payload, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **opt, no_raise: no_raise)
  end

  # Invoked from another thread to push acquired data back to the client.
  #
  # @param [Hash{Symbol=>*}] payload
  # @param [Boolean, nil]    no_raise   Passed to #stream_send.
  # @param [Hash]            opt
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *response()*
  # @see file:javascripts/channels/submit-channel.js *_createResponse()*
  #
  def self.final_response(payload, no_raise: nil, **opt)
    payload = SubmitChannel::FinalResponse.wrap(payload, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **opt, no_raise: no_raise)
  end

  # Invoked from another thread to push intermediate data back to the client.
  #
  # @param [Hash{Symbol=>*}] payload
  # @param [Boolean, nil]    no_raise   Passed to #stream_send.
  # @param [Hash]            opt
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *response()*
  # @see file:javascripts/channels/submit-channel.js *_createResponse()*
  #
  def self.step_response(payload, no_raise: nil, **opt)
    payload = SubmitChannel::StepResponse.wrap(payload, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **opt, no_raise: no_raise)
  end

  # Invoked from another thread to push acquired data back to the client.
  #
  # @param [Hash{Symbol=>*}] payload
  # @param [Boolean, nil]    no_raise   Passed to #stream_send.
  # @param [Hash]            opt
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js    *response()*
  # @see file:javascripts/channels/submit-channel.js *_createResponse()*
  #
  def self.control_response(payload, no_raise: nil, **opt)
    payload = SubmitChannel::ControlResponse.wrap(payload, **opt)
    payload.convert_to_data_url! if invalid_payload_size(payload)
    stream_send(payload, meth: __method__, **opt, no_raise: no_raise)
  end

end

__loading_end(__FILE__)
