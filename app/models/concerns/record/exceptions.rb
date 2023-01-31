# app/models/concerns/record/exceptions.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Record::Exceptions                                                       # NOTE: from UploadWorkflow::Errors

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Debug

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Raise an exception.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [Any, nil]                                                  value
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  # @see ExceptionHelper#failure
  #
  def failure(problem, value = nil)                                             # NOTE: from UploadWorkflow::Errors
    ExceptionHelper.failure(problem, value, model: :entry)
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
    # noinspection RubyMismatchedArgumentType
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
