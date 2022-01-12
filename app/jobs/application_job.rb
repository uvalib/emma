# app/jobs/application_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common base for Active Job classes.
#
# @!method job_name
#
class ApplicationJob < ActiveJob::Base

  include Emma::Common
  include Emma::Debug

  include_submodules(self)

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ApplicationJob::Properties
    include ApplicationJob::Logging
    # :nocov:
  end

  # ===========================================================================
  # :section: ActiveJob exceptions
  # ===========================================================================

  discard_on ActiveRecord::ActiveRecordError do |job, error|
    __debug_job(job) { "DATABASE ERROR - #{error.inspect}" } # TODO: remove block
  end

  retry_on ActiveRecord::ConnectionTimeoutError do |job, error|
    __debug_job(job) { "RETRY FAILED - #{error.inspect}" } # TODO: remove block
  end

  # ===========================================================================
  # :section: ActiveJob::Core overrides
  # ===========================================================================

  public

  def initialize(*arguments, **opt)
    cb     = opt.delete(:callback)
    cb_opt = opt.slice(:cb_receiver, :cb_method).presence
    job_warn { "ignoring #{cb_opt.inspect}" } if cb && cb_opt
    opt[:callback] = AsyncCallback.new(cb)    if (cb ||= cb_opt)
    opt.except!(*cb_opt.keys)                 if cb_opt
    arguments << opt                          if opt.present?
    super(*arguments)
  end

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  def perform(*)
    not_implemented 'to be overridden by the subclass'
  end

  # Run the job immediately.
  #
  # @param [Array] args               Ignored.
  #
  # @return [Any]                     Return value of #perform.
  #
  def perform_now(*args)
    __debug_job(__method__) { "`arguments` = #{arguments_inspect}" } # TODO: remove
    job_warn { "ignoring method args #{args.inspect}" } if args.present?
    super()
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
    __debug_job(__method__) { "`options` = #{item_inspect(options)}" } # TODO: remove
    job_warn { "ignoring method args #{args.inspect}" } if args.present?
    enqueue(options)
  end

  # Called from #perform to initiate a callback if one was supplied via the job
  # arguments.
  #
  # @param [AsyncCallback, nil] callback
  # @param [Hash]               opt       Passed to #cb_schedule.
  #
  # @option opt [AsyncCallback] :callback
  #
  # @return [void]
  #
  def perform_callback(callback, **opt)
    $stderr.puts "..................... #{self.class}.perform_callback | callback = #{callback.inspect}"
    job_warn { 'ignoring blank callback' } unless callback
    callback&.cb_schedule(**opt)
  end

end

# Namespace for app/jobs/attachment.
module Attachment
end

__loading_end(__FILE__)
