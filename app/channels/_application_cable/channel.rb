# app/channels/_application_cable/channel.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common logic for all channels.
#
class ApplicationCable::Channel < ActionCable::Channel::Base

  include ApplicationCable::Common
  include ApplicationCable::Payload

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  rescue_from 'MyError', with: :deliver_error_message # TODO: ???

  # ===========================================================================
  # :section: ActionCable callbacks
  # ===========================================================================

  if DEBUG_CABLE

    before_subscribe do
      __debug_cable('--->>> CABLE SUB', params.inspect)
    end

    after_subscribe do
      __debug_cable('<<<--- CABLE SUB', params.inspect)
    end

    before_unsubscribe do
      __debug_cable('--->>> CABLE UNSUB', params.inspect)
    end

    after_unsubscribe do
      __debug_cable('<<<--- CABLE UNSUB', params.inspect)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # stream_id
  #
  # @return [String, nil]
  #
  # @see file:javascripts/shared/cable-channel.js *streamId()*
  #
  def stream_id
    params[:stream_id]
  end

  # stream_name
  #
  # @param [String, Symbol, nil] base
  #
  # @return [String]
  #
  # @see file:javascripts/shared/cable-channel.js *streamName()*
  #
  def stream_name(base = channel_name)
    [base, stream_id].compact.join('_')
  end

  # ===========================================================================
  # :section: ActionCable::Channel::Base overrides
  # ===========================================================================

  protected

  # Setup for a subscription called when the consumer has successfully become a
  # subscriber to this channel.
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-consumer.js *createChannel()*
  #
  def subscribed
    __debug_cable(__method__)
    reject unless current_user&.can?(:get_job_result, Manifest)
    stream_from stream_name
  end

  # Any cleanup needed when the channel is unsubscribed.
  #
  # @return [void]
  #
  # @see file:javascripts/shared/cable-channel.js  *disconnect()*
  # @see file:javascripts/shared/cable-consumer.js *closeChannel()*
  #
  def unsubscribed
    __debug_cable(__method__)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Receive data from the client.
  #
  # @param [any, nil] payload
  # @param [Hash]     opt
  #
  # @return [Hash]
  #
  def stream_recv(payload, **opt)
    opt[:stream_name] ||= stream_name
    opt[:user]        ||= current_user&.to_s
    opt[:meth]        ||= __method__
    normalize_inbound(payload, **opt)
  end

  # Push data to the client.
  #
  # @param [ApplicationCable::Response] payload
  # @param [Hash]                       opt
  #
  # @option opt [Boolean] :fatal      Passed to #stream_send.
  #
  # @return [void]
  #
  def stream_send(payload, **opt)
    opt[:stream_name] ||= stream_name
    opt[:user]        ||= current_user&.to_s
    opt[:meth]        ||= __method__
    self.class.stream_send(payload, **opt)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Push data to the client.
  #
  # @param [ApplicationCable::Response] payload
  # @param [Boolean]                    fatal
  # @param [Hash]                       opt
  #
  # @return [void]
  #
  def self.stream_send(payload, fatal: true, **opt)
    meth   = opt[:meth] ||= __method__
    s_id   = opt.delete(:stream_id)
    stream = opt.delete(:stream_name) || (s_id && "#{channel_name}_#{s_id}")
    if stream.present?
      data = normalize_outbound(payload, **opt)
      ActionCable.server.broadcast(stream, data)
    else
      __debug_cable(meth, (error = "#{meth}: No stream given"))
      raise(error) if fatal
    end
  end

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  protected

  def deliver_error_message(e)
    broadcast_to('errors', e.message) # E.g., send to "lookup:errors"
  end

end

__loading_end(__FILE__)
