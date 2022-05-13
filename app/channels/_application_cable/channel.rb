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

  public

  # stream_id
  #
  # @return [String, nil]
  #
  # @see file:app/assets/javascripts/channels/lookup_channel.js *streamId*
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
  # @see file:app/assets/javascripts/channels/lookup_channel.js *streamName*
  #
  def stream_name(base = channel_name)
    [base, stream_id].compact.join('_')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Setup for a subscription.
  #
  # @return [void]
  #
  # @see file:app/assets/javascripts/channels/consumer.js *createChannel*
  #
  def subscribed
    __debug_cable(__method__)
    stream_from stream_name
  end

  # Any cleanup needed when channel is unsubscribed.
  #
  # @return [void]
  #
  # @see file:app/assets/javascripts/channels/lookup_channel.js  *disconnect*
  # @see file:app/assets/javascripts/channels/consumer.js        *closeChannel*
  #
  def unsubscribed
    __debug_cable(__method__)
    # TODO: abort any pending lookup requests
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
