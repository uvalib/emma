# app/channels/_application_cable/payload.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common logic for all channels.
#
module ApplicationCable::Payload

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  CHANNEL_PARAMS = %i[stream_id stream_name meth].freeze

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

  # template
  #
  # @return [Hash{Symbol=>*}]
  #
  def template
    not_implemented 'to be overridden by the subclass'
  end

  # default_status
  #
  # @return [String, nil]
  #
  def default_status
  end

  # Hash keys which should not be included with the data stored in the class
  # instance.
  #
  # @type [Array<Symbol>]
  #
  def ignored_keys
    CHANNEL_PARAMS
  end

  # Setup stored request values.
  #
  # @param [Hash, nil] store
  # @param [*]         values
  # @param [Hash]      opt
  #
  def set_payload(store = nil, values = nil, **opt)
    store, values = [nil, store] if values.nil?
    store   ||= {}
    opt     = payload_normalize(opt, except: nil)
    payload = extract_hash!(opt, *template.keys)
    if values.is_a?(store.class)
      store.update(values)
    else
      store.update(template)
      payload = payload_normalize(values).merge!(payload) if values.present?
    end
    store.update(payload) if payload.present?
    store[:time]    ||= Time.now
    store[:class]   ||= store.class.name
    store[:status]  ||= default_status if default_status
    store[:options] ||= {}
    store[:options].merge!(opt)
    store[:options][:thread_id] ||= Thread.current.name
    # noinspection RubyMismatchedReturnType
    store
  end

  # payload_normalize
  #
  # @param [*] value
  #
  # @return [Hash{Symbol=>*}]
  #
  # == Implementation Notes
  # Message classes based on a Hash data item require #to_h in order to avoid
  # propagating out-of-band data.
  #
  def payload_normalize(value, except: ignored_keys)
    return {} if value.nil?
    value =
      case value
        when ApplicationCable::Response, ApplicationJob::Response
          value.to_h
        when Hash
          value.symbolize_keys
        else
          { data: value }.deep_symbolize_keys
      end
    value.except!(*except) if except.present?
    value.deep_transform_values! do |v|
      case v
        when Proc, Method then nil
        when Hash, Array  then v.compact
        else                   v.respond_to?(:to_h) ? v.to_h.compact : v
      end
    end
    value.compact!
    value
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
