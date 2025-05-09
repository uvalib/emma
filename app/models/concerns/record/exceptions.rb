# app/models/concerns/record/exceptions.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# @note From UploadWorkflow::Errors
module Record::Exceptions

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
  # @param [any, nil]                                                  value
  # @param [Boolean, String]                                           log
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  # @note From UploadWorkflow::Errors#raise_failure
  #
  def raise_failure(problem, value = nil, log: true, **)
    log = "#{self_class}.#{calling_method}" if log.is_a?(TrueClass)
    ExceptionHelper.raise_failure(problem, value, model: :upload, log: log)
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

  # ===========================================================================
  # :section: FlashHelper::FlashPart overrides
  # ===========================================================================

  protected

  # A hook for treating the first part of an entry as special.
  #
  # @param [any, nil] src
  # @param [Hash]     opt
  #
  # @return [ActiveSupport::SafeBuffer, String, nil]
  #
  # @note From UploadWorkflow::Errors::FlashPart#render_topic
  #
  def render_topic(src, **opt)
    src = Record::Rendering.make_label(src, default: nil) || src
    super
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
# @note Analogous to UploadWorkflow::Errors::SubmitError
#
class Record::SubmitError < Record::Error
end

__loading_end(__FILE__)
