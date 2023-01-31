# app/jobs/submit_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SubmitJob < ActiveJob::Base

  include ApplicationJob::Methods
  include ApplicationJob::Logging

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  self.queue_name_prefix = 'submit'

  queue_as { manifest_id }

  attr_accessor :manifest_id

  # ===========================================================================
  # :section: Class Methods
  # ===========================================================================

  public

  # queue_for
  #
  # @param [SubmitJob, Manifest, String, *] manifest
  #
  # @return [String, nil]
  #
  def self.queue_for(manifest)
    id = manifest.try(:manifest_id) || manifest.try(:id) || manifest
    queue_name_from_part(id) if id.is_a?(String)
  end

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # Perform submission task(s), invoking #waiter_task if the job arguments
  # contain a SubmissionService::BatchSubmitRequest, or invoking #worker_task
  # otherwise.
  #
  # Expected ActiveJob arguments:
  # * argument[0]   request
  # * argument[1]   options:
  #
  # @option argument[2] [Symbol]  :job_type
  # @option argument[2] [Boolean] :no_raise
  #
  # @return [Hash]
  #
  def perform(*args, **opt)
    no_raise = record = nil
    super
    args     = arguments.dup
    opt      = args.extract_options!.dup
    no_raise = opt.delete(:no_raise)
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
      waiter_task(record, request, **opt)
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
      spawn:    'SPAWNING',
      step:     'STEP',
      late:     'LATE',
      done:     'DONE',
    },
    waiter: {
      nil =>    'WAITING',
      complete: 'COMPLETE', # All services replied.
      partial:  'PARTIAL',  # Some services timed out.
      timeout:  'TIMEOUT',  # All services timed out.
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
    job_opt  = extract_hash!(opt, *JOB_OPTIONS)
    meth     = job_opt[:meth]     || __method__
    start    = job_opt[:start]    || timestamp
    status   = job_opt[:status]
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
        late     = deadline && past_due(deadline)
        status   = :late if late
        status ||= rsp.batch? ? :spawn : :done
        rsp[:class]    = rsp.class.name
        rsp[:job_id]   = job_id
        rsp[:job_type] = job_type
        rsp[:late]     = late if late
        rsp[:status]   = JOB_STATUS[job_type][status]
      end
    result = response.to_h
    error  = response.error
    diag   = response.diagnostic

    if true # TODO: remove - testing
      error = error.is_a?(Hash) ? error.dup : { error: error }.compact
      error.merge!(_: 'worker', opt: opt, response: response[:class])
    end

    # Report results.
    __debug_job("#{meth} OUTPUT") { result }
    record.update(output: result, error: error, diagnostic: diag)
    SubmitChannel.final_response(result, **opt)

    # Add out-of-band identification data for the caller.
    result.merge!(active_job_id: job_id)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # waiter_task
  #
  # @param [JobResult]                             record
  # @param [SubmissionService::BatchSubmitRequest] request
  # @param [SubmissionService]                     service  Service instance
  # @param [Hash]                                  opt
  #
  # @return [Hash]
  #
  def waiter_task(record, request, service:, **opt)
    job_opt   = extract_hash!(opt, *JOB_OPTIONS)
    timeout   = job_opt.delete(:timeout)
    _meth     = job_opt[:meth]     ||= __method__
    start     = job_opt[:start]    ||= timestamp
    deadline  = job_opt[:deadline] ||= timeout && (start + timeout)
    job_type  = job_opt[:job_type] || :waiter
    waiter_id = job_id

    # Send an initial response back to the client.
    payload  = {
      data:        request,
      job_id:      waiter_id,
      job_type:    job_type,
      manifest_id: manifest_id,
      start_time:  start,
    }
    SubmitChannel.initial_response(payload, **opt)

    # Spawn worker task jobs.
    job_opt.merge!(job_type: :worker)
    response = service.process(request, **opt, **job_opt)
    job_list, results = response.partition { |r| r.is_a?(SubmitJob) }

    # Await task completions (unless opt[:no_async] is true).
    if job_list.present?

      # noinspection RubyMismatchedArgumentType
      job_table = ApplicationJob::Table.new(job_list)

      notifications_subscribe do |_, _, _, _, event_payload|

        data   = event_payload&.dig(:result)&.try(:value)
        job_id = data&.dig(:active_job_id)

        # Because this block will be invoked by the completion of any GoodJob
        # job, only pay attention to the completion of a job that was started
        # by this waiter instance.
        if job_table.include?(job_id)

          # Update the table with information about the completed job.
          end_time = timestamp
          overtime = deadline && positive_float(end_time - deadline)
          job_table[job_id] = data.except(:active_job_id)
          job_table[job_id][:late] ||= overtime if overtime

          # If all jobs spawned by this waiter have completed then send the
          # final response back to the client and remove this waiter instance
          # from the list of event subscribers.
          if job_table.completed?
            notifications_unsubscribe
            total, error = job_table.summarize.values_at(:total, :error)
            status = overtime ? :timeout : :complete
            result =
              SubmitChannel::SubmitResponse.new(**opt).tap do |rsp|
                rsp[:count]       = total
                rsp[:data]        = job_table.map { |k,v| [k, v[:data]] }.to_h
                rsp[:discard]     = error if error
                rsp[:job_id]      = waiter_id
                rsp[:job_type]    = job_type
                rsp[:manifest_id] = manifest_id
                rsp[:status]      = JOB_STATUS[job_type][status]
                rsp[:start_time]  = start
                rsp[:end_time]    = end_time
                rsp[:duration]    = (end_time - start)
              end
            record.update(output: result, error: error)
            SubmitChannel.final_response(result, **opt)
          end
        end
      end
    end

    # Update the 'job_results' entry for this waiter.  If opt[:no_async] is
    # true, this appears only after all workers have completed.  Otherwise,
    # this initial information will be overwritten by the notification
    # subscriber block.
    error = { _: 'WAITER', opt: opt, response: response.class.name }
    record.update(output: results, error: error)

    payload.merge!(data: results)
  end

end

__loading_end(__FILE__)
