# app/models/concerns/record/exceptions.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

#require_relative 'rendering' # NOTE: commented-out

module Record::Exceptions                                                       # NOTE: from UploadWorkflow::Errors

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Debug

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Error types and messages.                                                   # NOTE: from UploadWorkflow::Errors::UPLOAD_ERROR
  #
  # @type [Hash{Symbol=>(String,Class)}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  ENTRY_ERROR =
    I18n.t('emma.error.entry').transform_values { |properties|
      next unless properties.is_a?(Hash)
      text = properties[:message]
      err  = properties[:error]
      err  = "Net::#{err}" if err.is_a?(String) && !err.start_with?('Net::')
      err  = err&.safe_constantize unless err.is_a?(Module)
      err  = err.exception_type if err.respond_to?(:exception_type)
      [text, err]
    }.compact.symbolize_keys.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Raise an exception.
  #
  # If *problem* is a symbol, it is used as a key to #ENTRY_ERROR with *value*
  # used for string interpolation.
  #
  # Otherwise, error message(s) are extracted from *problem*.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [Any]                                                       value
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  def failure(problem, value = nil)                                             # NOTE: from UploadWorkflow::Errors
    __debug_items("ENTRY WF #{__method__}", binding)

    # If any failure is actually an internal error, re-raise it now so that it
    # will result in a stack trace when it is caught and processed.
    [problem, *value].each { |v| re_raise_if_internal_exception(v) }

    report = nil
    msg, error = problem.is_a?(Symbol) ? ENTRY_ERROR[problem] : [problem, nil]
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The exception raised within the instance.
    #
    # @return [Record::Error, nil]
    #
    attr_reader :exception

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the instance has experienced an exception.
    #
    def error?
      @exception.present?
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Associate an exception with the instance.
    #
    # @param [Class<Record::Error>, Record::Error, Exception, nil] error
    # @param [Hash] opt   Passed to initializer if *error* is a class.
    #
    # @return [Record::Error]         New value of @exception.
    #
    #--
    # noinspection RubyNilAnalysis,RubyMismatchedArgumentType
    #++
    def set_error(error, **opt)
      error = error.new(**opt) if error.is_a?(Class)
      @exception =
        case error
          when Record::Error, nil then error
          when Exception          then Record::Error.new(error)
          else Log.warn { "#{__method__}: #{error.class} unexpected" }
        end
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    include InstanceMethods if Record.record_class?(base)

  end

end

# Each instance translates to a distinct line in the flash message.
#
class Record::Exceptions::FlashPart < FlashHelper::FlashPart

  include Record::Rendering

  # ===========================================================================
  # :section: FlashHelper::FlashPart overrides
  # ===========================================================================

  protected

  # A hook for treating the first part of a entry as special.
  #
  # @param [Any]  src
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, String, nil]
  #
  def render_topic(src, **opt)                                                  # NOTE: from UploadWorkflow::Errors::FlashPart
    src = make_label(src, default: '').presence || src
    super(src, **opt)
  end

end

# Base class for workflow errors involving records.
#
class Record::Error < ExecError
  include Record::Exceptions
end

# Exception raised when the specified record(s) could not be found, but through
# mechanisms that did not raise an ActiveRecord::RecordNotFound.
#
class Record::NotFound < Record::Error
end

# Exception raised when criteria were missing to specify the record(s).
#
class Record::StatementInvalid < Record::Error
end

# Exception raised when a submission is incomplete or invalid.
#
class Record::SubmitError < Record::Error                                       # NOTE: from UploadWorkflow::Errors
end

__loading_end(__FILE__)
