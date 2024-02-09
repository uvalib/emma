# app/channels/_application_cable/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common logic for all channels.
#
module ApplicationCable::Common

  include ApplicationCable::Logging

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  CHANNEL_PARAMS = %i[stream_id stream_name meth].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Hash keys which should not be included with the data stored in the class
  # instance.
  #
  # @type [Array<Symbol>]
  #
  def ignored_keys
    CHANNEL_PARAMS
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Normalize received stream data.
  #
  # @param [any, nil]    payload
  # @param [Symbol, nil] meth         Calling method (for diagnostics).
  # @param [Hash]        opt
  #
  # @return [Hash]
  #
  def normalize_inbound(payload, meth: nil, **opt)
    __debug_cable_data((meth || __method__), payload)
    payload = { data: payload } unless payload.nil? || payload.is_a?(Hash)
    payload = payload&.deep_symbolize_keys || {}
    payload.merge!(opt.deep_symbolize_keys)
  end

  # Normalize stream payload data.
  #
  # @param [any, nil]    payload
  # @param [Symbol, nil] meth         Calling method (for diagnostics).
  # @param [Hash]        opt
  #
  # @return [Hash]
  #
  def normalize_outbound(payload, meth: nil, **opt)
    __debug_cable_data((meth || __method__), payload)
    ApplicationCable::Response.wrap(payload, **opt).to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
