# app/channels/_application_cable/payload.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common logic for all channels.
#
module ApplicationCable::Payload

  include ApplicationCable::Common

  include Emma::ThreadMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The limit on payload size due to the PostgreSQL-based implementation.
  #
  # @return [Integer]
  #
  # @see https://www.postgresql.org/docs/11/sql-notify.html
  #
  MAX_PAYLOAD_SIZE = 8000

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Determine the serialized size of the given item.
  #
  # @param [any, nil] payload
  #
  # @return [Integer]
  #
  def payload_size(payload)
    ActiveJob::Arguments.serialize([payload]).first.to_json.size
  end

  # If the payload would cause a PG::InvalidValueException return its size.
  #
  # @param [any, nil] payload
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

  # Response data value entries defined by the including class.
  #
  # @return [Hash]
  #
  def template
    must_be_overridden
  end

  # The characteristic status value defined by the including class.
  #
  # @return [String, nil]
  #
  def default_status
  end

  # Set stored request values from the template defined by the including class.
  #
  # @param [Hash, nil] target
  # @param [any, nil]  values
  # @param [Hash]      opt
  #
  # @return [Hash]
  #
  def set_payload(target = nil, values = nil, **opt)
    store, values = values ? [target, values] : [nil, target]
    store ||= {}
    payload = payload_normalize(opt, except: []).extract!(*template.keys)
    if values.is_a?(store.class)
      store.update(values)
    else
      store.update(template)
      payload = payload_normalize(values).merge!(payload) if values.present?
    end
    store.update(payload) if payload.present?
    store[:time]      ||= Time.now
    store[:class]     ||= store.class.name
    store[:status]    ||= default_status if default_status
    store[:thread_id] ||= thread_name
    store.except!(SubmissionService::REQUEST_OPT)
  end

  # Transform a response value to a normalized form.
  #
  # @param [any, nil]           value
  # @param [Array, Symbol, nil] except    Default: `#ignored_keys`.
  #
  # @return [Hash]
  #
  # === Implementation Notes
  # Message classes based on a Hash data item require #to_h in order to avoid
  # propagating out-of-band data.
  #
  def payload_normalize(value, except: nil)
    return {} if value.nil?
    except ||= ignored_keys
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
    value.deep_transform_values { |v|
      next if v.is_a?(Proc) || v.is_a?(Method)
      v.respond_to?(:to_h) ? v.to_h.compact : v
    }.compact
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
