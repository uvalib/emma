# app/helpers/exception_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

module ExceptionHelper

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Debug

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Error types and messages.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>(String,Class)}}]
  #
  MODEL_ERROR =
    config_section('emma.error').map { |model, model_entry|
      next if model.start_with?('_') || !model_entry.is_a?(Hash)
      entry = model_entry.select { |_, error_entry| error_entry.is_a?(Hash) }
      next if entry.blank?
      value = model_entry.except(*entry.keys)
      value = value.map { |k, v| [k.to_sym, v] if (k = k.to_s.sub!(/^_/, '')) }
      value = value.compact.to_h.presence
      entry =
        entry.transform_values { |properties|
          m, e = properties.values_at(:message, :error)
          m = interpolate(m, value) if value
          e = e.to_s                if e.is_a?(Symbol)
          e = "Net::#{e}"           if e.is_a?(String) && !e.include?('::')
          e = e.safe_constantize    if e.is_a?(String)
          e = e.exception_type      if e.respond_to?(:exception_type)
          [m, e]
        }.compact
      [model, entry]
    }.compact.to_h.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Raise an exception.
  #
  # If *problem* is a symbol, it is used as a key into #MODEL_ERROR with
  # *value* used for string interpolation.
  #
  # Otherwise, error message(s) are extracted from *problem*.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [any, nil]                                                  value
  # @param [Symbol]                                                    model
  # @param [Boolean, String]                                           log
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  def raise_failure(problem, value = nil, model:, log: false, **)
    __debug_items("#{model.upcase} WF #{__method__}", binding)

    # If any failure is actually an internal error, re-raise it now so that it
    # will result in a stack trace when it is caught and processed.
    [problem, *value].each do |arg|
      re_raise_if_internal_exception(arg) if arg.is_a?(Exception)
    end

    # Process the initial argument.
    rpt = msg = err = nil
    case problem
      when ExecReport then rpt = problem
      when Exception  then err = problem
      when String     then msg = problem
      when Symbol     then msg, err = MODEL_ERROR.dig(model, problem)
    end
    err = err.safe_constantize if err.is_a?(String) || err.is_a?(Symbol)

    value, _ = MODEL_ERROR.dig(model, value) if value.is_a?(Symbol)

    # Perform message interpolations if required to generate the report.
    if rpt.nil? && msg.is_a?(String)
      ary = value.is_a?(Array)  # Multiple item values.
      int = msg.include?('%')   # Message expects value interpolation.
      case
        when ary && int   then msg %= value.size
        when ary          then msg += " (#{value.size})"
        when int && value then msg %= value.to_s; value = nil
        when int          then msg %= '???'
      end
    end
    rpt ||= ExecReport.new(msg, *value) if msg
    rpt ||= ExecReport.new(err, *value) if err
    rpt ||= ExecReport.new(problem.to_s, *value)

    # Emit a log entry if requested.
    if log
      Log.warn do
        case log
          when TrueClass then log = "#{self_class}.#{calling_method}"
          when Symbol    then log = "#{self_class}.#{log}"
        end
        msg = rpt.render(html: false).join('; ')
        "#{log}: #{msg}"
      end
    end

    # Find or create the exception and raise it.
    err ||= rpt.exception
    err ||= Array.wrap(value).find { |v| v.is_a?(Exception) }
    err ||= Record::SubmitError
    err.is_a?(Exception) and raise(err) or raise(err, rpt.render)
  end

end

__loading_end(__FILE__)
