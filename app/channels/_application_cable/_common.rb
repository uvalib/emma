# app/channels/_application_cable/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common logic for all channels.
#
module ApplicationCable::Common

  include Emma::Debug

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @see https://www.postgresql.org/docs/11/sql-notify.html
  MAX_PAYLOAD_SIZE = 8000

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Determine the serialized size of the given item.
  #
  # @param [*] payload
  #
  # @return [Integer]
  #
  def payload_size(payload)
    ActiveJob::Arguments.serialize([payload]).first.to_json.size
  end

  # If the payload would cause a PG::InvalidValueException return its size.
  #
  # @param [*] payload
  #
  # @return [Integer]                 The size that would result in failure.
  # @return [nil]                     The payload is not too large.
  #
  def invalid_payload_size(payload)
    size = payload_size(payload)
    size unless size < MAX_PAYLOAD_SIZE
  end

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
    __debug_cable(meth || __method__) do
      "#{payload.class} = #{payload.inspect.truncate(512)}"
    end
    case payload
      when nil  then payload = {}
      when Hash then payload = payload.dup
      else           payload = { data: payload }
    end
    payload.merge!(opt).deep_symbolize_keys!
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
    __debug_cable(meth || __method__) do
      "#{payload.class} = #{payload.inspect.truncate(512)}"
    end
    ApplicationCable::Response.cast(payload, **opt).to_h
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
