# app/channels/_application_cable/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common logic for all channels.
#
module ApplicationCable::Common

  include ApplicationCable::Payload
  include Emma::Debug

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Normalize received stream data.
  #
  # @param [*]           payload
  # @param [Symbol, nil] meth         Calling method (for diagnostics).
  # @param [Hash]        opt
  #
  # @return [Hash{Symbol=>*}]
  #
  def normalize_inbound(payload, meth: nil, **opt)
    __debug_cable_data((meth || __method__), payload)
    payload = { data: payload } unless payload.nil? || payload.is_a?(Hash)
    payload = payload&.deep_symbolize_keys || {}
    payload.merge!(opt.deep_symbolize_keys)
  end

  # Normalize stream payload data.
  #
  # @param [*]           payload
  # @param [Symbol, nil] meth         Calling method (for diagnostics).
  # @param [Hash]        opt
  #
  # @return [Hash{Symbol=>*}]
  #
  def normalize_outbound(payload, meth: nil, **opt)
    __debug_cable_data((meth || __method__), payload)
    ApplicationCable::Response.wrap(payload, **opt).to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Send debugging output to the console.
  #
  # @param [Array<*>] args
  # @param [Hash]     opt
  #
  # @return [void]
  #
  def __debug_cable(*args, **opt)
    opt[:separator] ||= "\n\t"
    t     = Thread.current.name
    name  = self_class
    args  = args.compact.join(Emma::Debug::DEBUG_SEPARATOR)
    added = block_given? ? yield : {}
    __debug_items("#{name} #{args}", **opt) do
      added.is_a?(Hash) ? added.merge(thread: t) : [*added, "thread #{t}"]
    end
  end
    .tap { |meth| neutralize(meth) unless DEBUG_CABLE }

  # Send sent/received WebSocket data to the console.
  #
  # @param [Symbol] meth
  # @param [*]      data
  #
  # @return [void]
  #
  def __debug_cable_data(meth, data)
    __debug_cable(meth) do
      "#{data.class} = #{data.inspect.truncate(512)}"
    end
  end
    .tap { |meth| neutralize(meth) unless DEBUG_CABLE }

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
