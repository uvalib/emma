# app/jobs/submit_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SubmitJob < ApplicationJob

  include GoodJob::ActiveJobExtensions::Batches

  # ===========================================================================
  # :section: ActiveJob properties
  # ===========================================================================

  self.queue_name_prefix = 'submit'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [String]
  attr_accessor :manifest_id

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # Perform submission task(s), invoking #waiter_task if the job arguments
  # contain a SubmissionService::BatchSubmitRequest.
  #
  # Unlike the (current) implementation of LookupJob, the "worker task" is not
  # defined as an instance method.  Instead #perform_later is overridden to
  # create a GoodJob::Batch which handles that functionality.
  #
  # Expected ActiveJob arguments:
  # * argument[0]   request
  # * argument[1]   options:
  #
  # @option argument[2] [Symbol]  :job_type
  # @option argument[2] [Boolean] :fatal
  #
  # @return [Hash]
  #
  def perform(*args, **opt)
    no_raise = record = nil
    super
    args     = arguments.dup
    opt      = args.extract_options!.dup
    no_raise = false?(opt.delete(:fatal))
    meth     = opt[:meth]  ||= "#{self.class}.#{__method__}"
    start    = opt[:start] ||= timestamp
    timeout  = opt[:timeout]

    _service = opt[:service]        or raise ExecError, "#{meth}: no service"
    request  = args.shift.presence  or raise ExecError, "#{meth}: no request"
    record   = JobResult.create(active_job_id: job_id)

    self.manifest_id = request.manifest_id
    opt[:deadline] ||= (start + timeout) if timeout
    opt[:job_type] ||= request.batch? ? :waiter : :worker

    if opt[:job_type] == :worker
      worker_task(record, request, **opt)
    else
      raise "#{opt[:job_type]} job_type unexpected"
    end

  rescue => error
    record&.update(error: error)
    raise error unless no_raise
    __output "JOB ERROR: #{error.full_message}"
    {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>Hash{Symbol,nil=>String}}]
  JOB_STATUS = {
    worker: {
      nil =>    'WORKING',
      step:     SubmitChannel::Response::STATUS_STEP,
      done:     SubmitChannel::Response::STATUS_INTERMEDIATE,
    },
    waiter: {
      nil =>    'WAITING',
      complete: SubmitChannel::Response::STATUS_FINAL,
    }
  }.deep_freeze

  JOB_TYPES   = JOB_STATUS.keys.freeze

  JOB_OPTIONS = %i[meth start status timeout deadline job_type].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # worker_task
  #
  # @param [JobResult]                  record
  # @param [SubmissionService::Request] request
  # @param [SubmissionService]          service   Service instance
  # @param [Hash]                       opt
  #
  # @return [Hash]
  #
  # @see SubmitChannel::Response#TEMPLATE
  #
  def worker_task(record, request, service:, **opt)
    job_opt  = opt.extract!(*JOB_OPTIONS)
    meth     = job_opt[:meth]     || __method__
    start    = job_opt[:start]    || timestamp
    timeout  = job_opt[:timeout]
    deadline = job_opt[:deadline] || (timeout && (start + timeout))
    job_type = job_opt[:job_type] || :worker

    # Perform service operation.
    step_callback =
      ->(data, **cb_opt) do
        cb_opt[:job_id]   ||= job_id
        cb_opt[:job_type] ||= job_type
        SubmitChannel.step_response(data, **opt, **cb_opt)
      end
    response =
      service.process(request, **opt, callback: step_callback).tap do |rsp|
        # noinspection RubyMismatchedArgumentType
        overtime = deadline && past_due(deadline)
        status   = :done
        rsp[:class]    = rsp.class.name
        rsp[:job_id]   = job_id
        rsp[:job_type] = job_type
        rsp[:late]     = overtime if overtime
        rsp[:status]   = JOB_STATUS.dig(job_type, status) || '???'
      end
    result = response.to_h
    error  = response.error
    diag   = response.diagnostic

    if true # TODO: remove - testing
      error = error.is_a?(Hash) ? error.dup : { error: error }.compact
      error.merge!(_: 'worker', opt: opt, response: response[:class])
    end

    # Report results.
    __debug_job(meth, 'OUTPUT') { result }
    record.update(output: result, error: error, diagnostic: diag)
    SubmitChannel.final_response(result, **opt)

    # Add out-of-band identification data for the caller.
    result.merge!(active_job_id: job_id)
  end

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # Process SubmissionService::BatchSubmitRequest jobs through
  # GoodJob::Batch#enqueue; all other request jobs are queued the normal way
  # via ActiveJob::Enqueuing#enqueue.
  #
  # @param [Array] args               Assigned to ActiveJob::Core#arguments.
  # @param [Hash]  opt
  #
  # @return [GoodJob::BatchRecord]
  # @return [SubmitJob, false]
  #
  def self.perform_later(*args, **opt)
    __debug_job(__method__) { { args: args, opt: opt } } # TODO: remove
    return super unless args.first.is_a?(SubmissionService::BatchSubmitRequest)

    # Extract batch sub-requests.
    request  = args.shift
    requests = request.requests
    count    = requests&.size

    # Extract job-related options.
    opt.except!(:meth, :job_type)
    job_opt  = opt.extract!(*JOB_OPTIONS)
    start    = job_opt[:start]       ||= timestamp
    job_type = job_opt[:job_type]    ||= :waiter
    manifest = job_opt[:manifest_id] ||= request.manifest_id
    job_opt.merge!(opt)

    # Spawn a job for each batch.
    properties = job_opt.merge(count: count, on_finish: SubmitJobCallbackJob)
    properties[:on_success] = properties[:on_finish] # NOTE: trial; may go away
    properties[:on_discard] = properties[:on_finish] # NOTE: trial; may go away
    GoodJob::Batch.enqueue(**properties) {
      requests.each do |req|
        perform_later(req, *args, **job_opt, job_type: :worker)
      end
    }.tap { |batch|
      # Send an initial response back to the client.
      payload = {
        data:        requests,
        job_id:      batch.id, # NOTE: not correlated with ActiveJob identity
        job_type:    job_type,
        manifest_id: manifest,
        start_time:  start,
      }
      SubmitChannel.initial_response(payload, **opt)
    }
  end

end

# The job invoked when the batch job queued in SubmitJob::perform_later is run.
#
# GoodJob::Batch allows for distinct job classes to handle the :discard,
# :success, and :finish events, but also supports the ability of a single class
# to be defined to handle any of them.
#
class SubmitJobCallbackJob < ApplicationJob

  JOB_TYPE = :waiter

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # Invoked when the batch job enqueued in SubmitJob#perform_later is run.
  #
  # The *options* argument has only one entry: the :event which indicates the
  # nature of this execution (which allows a single job class to be defined to
  # handle each of these events).
  #
  # @param {GoodJob::Batch} batch
  # @param {Hash}           options
  #
  # @see GoodJob::BatchRecord#_continue_discard_or_finish
  #
  def perform(batch, options)
    __debug_job(__method__) { { batch: batch, options: options } }
    case options[:event]
      when :finish  then on_finish(batch)
      when :success then on_success(batch)
      when :discard then on_discard(batch)
      else Log.warn { "#{self.class}: unexpected #{options.inspect}" }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Invoked when the batch job enqueued in SubmitJob#perform_later is run,
  # indicating that all sub-requests have finished.
  #
  # NOTE: `batch.properties` must include :stream_name (or :stream_id) in
  #   order to direct the ActionCable response to the client.
  #
  # @param {GoodJob::Batch} batch
  #
  def on_finish(batch)
    __debug_job('*** BATCH FINISHED - all jobs have finished') do
      { properties: batch.properties }
    end
    opt        = batch.properties
    opt, prop  = partition_hash(opt,  *ApplicationCable::CHANNEL_PARAMS)
    job, resp  = partition_hash(prop, *SubmitJob::JOB_OPTIONS)
    end_time   = timestamp
    start_time = job[:start]    || end_time
    timeout    = job[:timeout]
    deadline   = job[:deadline] || (timeout && (start_time + timeout))
    # noinspection RubyMismatchedArgumentType
    overtime   = deadline && past_due(deadline, end_time)

    resp[:job_id]     = batch.id
    resp[:job_type]   = JOB_TYPE
    resp[:data]       = nil # {}              # TODO: ???
    resp[:late]       = overtime if overtime
    resp[:start_time] = start_time
    resp[:end_time]   = end_time
    resp[:duration]   = end_time - start_time
    SubmitChannel.final_response(resp, **opt)
  end

  # Invoked if no GoodJob jobs were discarded.
  #
  # @param {GoodJob::Batch} batch
  #
  def on_success(batch)
    __debug_job('*** BATCH SUCCESS - all jobs have succeeded') { batch }
  end

  # Invoked when GoodJob job(s) are discarded.
  #
  # @param {GoodJob::Batch} batch
  #
  def on_discard(batch)
    __debug_job('*** BATCH DISCARD - job(s) have been discarded') { batch }
  end

end

__loading_end(__FILE__)
