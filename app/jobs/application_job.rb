# app/jobs/application_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common base for Active Job classes.
#
class ApplicationJob < ActiveJob::Base

  include ApplicationJob::Logging
  include ApplicationJob::Methods
  include ApplicationJob::Properties

  # ===========================================================================
  # :section: ActiveJob exceptions
  # ===========================================================================

  discard_on ActiveRecord::ActiveRecordError do |job, error|
    __debug_job(job) { "DATABASE ERROR - #{error.inspect}" }
  end

  # Most jobs are safe to ignore if underlying records are no longer available.
  #discard_on ActiveJob::DeserializationError

  retry_on ActiveRecord::ConnectionTimeoutError do |job, error|
    __debug_job(job) { "RETRY FAILED - #{error.inspect}" }
  end

  # Automatically retry jobs that encountered a deadlock
  #retry_on ActiveRecord::Deadlocked

  # ===========================================================================
  # :section: ActiveJob callbacks
  # ===========================================================================

  if DEBUG_JOB

    before_enqueue do
      __debug_job('--->>> ENQUEUE START', arguments_inspect)
    end

    after_enqueue do
      __debug_job('<<<--- ENQUEUE END  ', arguments_inspect)
    end

    before_perform do
      __debug_job('--->>> PERFORM START', arguments_inspect)
    end

    after_perform do
      __debug_job('<<<--- PERFORM END  ', arguments_inspect)
    end

  end

  # ===========================================================================
  # :section: ActiveJob::Core overrides
  # ===========================================================================

  public

  # initialize
  #
  # @param [any, nil] args            Assigned to ActiveJob::Core#arguments.
  # @param [Hash]     opt             Appended to ActiveJob::Core#arguments.
  #
  def initialize(*args, **opt)
    __debug_job(__method__) { { args: args, opt: opt } }
    super()
    set_arguments(*args, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Queue the job to be run asynchronously.
  #
  # @param [Array] args               Ignored.
  # @param [Hash]  options            Passed to ActiveJob::Enqueuing#enqueue.
  #
  # @return [FalseClass]              If the job could not be queued.
  # @return [ApplicationJob]          Otherwise *self* is returned.
  #
  def perform_later(*args, **options)
    __debug_job(__method__) { "options = #{item_inspect(options)}" }
    job_warn { "ignoring method args #{args.inspect}" } if args.present?
    enqueue(options)
  end

end

# Namespace for app/jobs/attachment.
#
# @note Currently unused.
# :nocov:
module Attachment
end
# :nocov:

__loading_end(__FILE__)
