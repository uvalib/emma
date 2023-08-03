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
    I18n.t('emma.error').map { |key, entry|
      next if key.start_with?('_') || !entry.is_a?(Hash)
      entry = entry.select { |_, properties| properties.is_a?(Hash) }
      next if entry.blank?
      entry =
        entry.transform_values { |properties|
          msg, err = properties.values_at(:message, :error)
          err = "Net::#{err}" if err.is_a?(String) && !err.start_with?('Net::')
          err = err&.safe_constantize unless err.is_a?(Module)
          err = err.exception_type    if err.respond_to?(:exception_type)
          [msg, err]
        }.compact
      [key, entry]
    }.compact.to_h.deep_symbolize_keys.deep_freeze

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
  # @param [*]                                                         value
  # @param [Symbol]                                                    model
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  def raise_failure(problem, value = nil, model:)
    model = model.to_sym
    __debug_items("#{model.upcase} WF #{__method__}", binding)

    # If any failure is actually an internal error, re-raise it now so that it
    # will result in a stack trace when it is caught and processed.
    [problem, *value].each { |v| re_raise_if_internal_exception(v) }

    report = nil
    msg, error =
      problem.is_a?(Symbol) ? MODEL_ERROR.dig(model, problem) : [problem, nil]
    if msg.is_a?(String)
      if msg.include?('%') # Message expects value interpolation.
        msg %= value.is_a?(Array) ? value.size : value.to_s
      elsif value.is_a?(Array) && value.many?
        msg += " (#{value.size})"
      end
    elsif msg.is_a?(ExecReport)
      report = msg if value.blank?
    end
    report ||= ExecReport.new(msg, *value)
    error  ||= report.exception || Record::SubmitError

    raise error, report.render
  end

end

__loading_end(__FILE__)
