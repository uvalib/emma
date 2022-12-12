# app/channels/_application_cable/channel.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common logic for all channels.
#
class ApplicationCable::Channel < ActionCable::Channel::Base

  include ApplicationCable::Common

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  rescue_from 'MyError', with: :deliver_error_message # TODO: ???

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
  # @param [String, nil] base
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
  # @param [*]   payload
  # @param [Hash] opt
  #
  # @param [Hash{Symbol=>*}]
  #
  def stream_recv(payload, **opt)
    opt[:meth] ||= __method__
    normalize_inbound(payload, **opt)
  end

  # Push data to the client.
  #
  # @param [ApplicationCable::Response] payload
  # @param [Hash]                       opt
  #
  # @return [void]
  #
  def stream_send(payload, **opt)
    opt[:stream_name] ||= stream_name
    opt[:user]        ||= current_user
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
  # @param [Hash]                       opt
  #
  # @return [void]
  #
  def self.stream_send(payload, **opt)
    meth   = opt.delete(:meth) || __method__
    s_id   = opt.delete(:stream_id)
    stream = opt.delete(:stream_name) || (s_id && "#{channel_name}_#{s_id}")
    raise "#{meth}: No stream given" unless stream.present?
    data   = normalize_outbound(payload, meth: meth, **opt)
    ActionCable.server.broadcast(stream, data)
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
