# app/jobs/lookup_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class LookupJob < ApplicationJob

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # Lookup the provided identifier(s) and transmit the result to the client.
  #
  # Expected ActiveJob arguments:
  # * argument[0]   LookupService::RemoteService subclass or subclass instance.
  # * argument[1]   Array of identifier strings or Hash table of arrays.
  # * argument[2]   Options:
  #
  # @option argument[2] [Symbol]  :job_type
  # @option argument[2] [Boolean] :fatal
  #
  # @return [Hash]
  #
  #--
  # === Variations
  #++
  #
  # @overload perform_later(services, request, **opt)
  #   The "waiter" task invoked via `LookupJob.perform_later`.
  #   @param [Array<Class,LookupService::RemoteService>]  services
  #   @param [LookupService::Request]                     request
  #   @param [Hash]                                       opt
  #   @return [Hash]
  #
  # @overload perform_later(service, request, **opt, job_type: :worker)
  #   A "worker" task invoked from within #waiter_task.
  #   @param [Class,LookupService::RemoteService]         service
  #   @param [LookupService::Request]                     request
  #   @param [Hash]                                       opt
  #   @return [Hash]  From LookupService::RemoteService#lookup_metadata
  #
  def perform(*args, **opt)
    no_raise = nil
    record   = JobResult.create(active_job_id: job_id)
    super
    args     = arguments.dup
    opt      = args.extract_options!.dup
    no_raise = false?(opt.delete(:fatal))
    meth     = opt[:meth]  ||= "#{self.class}.#{__method__}"
    start    = opt[:start] ||= timestamp
    timeout  = opt[:timeout]

    service  = args.shift.presence or raise ExecError, "#{meth}: no service"
    request  = args.shift.presence or raise ExecError, "#{meth}: no request"

    opt[:deadline] ||= (start + timeout) if timeout
    opt[:job_type] ||= service.is_a?(Array) ? :waiter : :worker

    # noinspection RubyMismatchedArgumentType
    if opt[:job_type] == :worker
      worker_task(record, service, request, **opt)
    else
      waiter_task(record, service, request, **opt)
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

  JOB_TYPES = JOB_STATUS.keys.freeze

  JOB_OPT   = %i[meth start status timeout deadline job_type].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # If *true*, each worker will send a response back to the client.  Otherwise,
  # the only response the client should expect is the one from the waiter task
  # after all of the worker tasks have either completed or timed-out.
  #
  # @type [Boolean]
  #
  WORKER_RESPONSE = true

  # worker_task
  #
  # @param [JobResult]                           record
  # @param [Class, LookupService::RemoteService] service
  # @param [LookupService::Request]              request
  # @param [Hash]                                opt
  #
  # @return [Hash]
  #
  # @see LookupService::Response#TEMPLATE
  #
  def worker_task(record, service, request, **opt)
    job_opt  = opt.extract!(*JOB_OPT)
    meth     = job_opt[:meth] ||= __method__

    # Perform lookup on the external service.
    response = worker_task_execution(service, request, **job_opt)
    result   = response.to_h
    error    = response.error
    diag     = response.diagnostic

    # Report results.
    __debug_job(meth, 'OUTPUT') { result }
    record.update(output: result, error: error, diagnostic: diag)
    LookupChannel.lookup_response(result, **opt) if WORKER_RESPONSE

    # Add out-of-band identification data for the caller.
    result.merge!(active_job_id: job_id)
  end

  # Perform lookup on the external service.
  #
  # @param [Class, LookupService::RemoteService] service
  # @param [LookupService::Request]              request
  # @param [Hash]                                opt
  #
  # @return [LookupService::Response]
  #
  def worker_task_execution(service, request, **opt)
    start    = opt[:start]    || timestamp
    timeout  = opt[:timeout]
    deadline = opt[:deadline] || (timeout && (start + timeout))
    job_type = opt[:job_type] || :worker
    status   = opt[:status]   || :done

    LookupService.get_from(service, request).tap do |rsp|
      # noinspection RubyMismatchedArgumentType
      status = :late if (overtime = deadline && past_due(deadline))
      rsp[:class]    = rsp.class.name
      rsp[:job_id]   = job_id
      rsp[:job_type] = job_type
      rsp[:late]     = overtime if overtime
      rsp[:status]   = JOB_STATUS.dig(job_type, status) || '???'
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # waiter_task
  #
  # @param [JobResult]                                 record
  # @param [Array<Class,LookupService::RemoteService>] services
  # @param [LookupService::Request]                    request
  # @param [Hash]                                      opt
  #
  # @return [Hash]
  #
  def waiter_task(record, services, request, **opt)
    services  = Array.wrap(services)
    job_opt   = opt.extract!(*JOB_OPT)
    timeout   = job_opt.delete(:timeout)
    meth      = job_opt[:meth]     ||= __method__
    start     = job_opt[:start]    ||= timestamp
    _deadline = job_opt[:deadline] ||= timeout && (start + timeout)
    job_type  = job_opt[:job_type] || :waiter
    waiter_id = job_id

    # Send an initial response back to the client.
    payload  = {
      data:     request,
      job_id:   waiter_id,
      job_type: job_type,
      service:  services.map(&:service_key),
    }
    LookupChannel.initial_response(payload, **opt)

    # Spawn worker tasks.
    j_opt = opt.slice(:stream_name).merge!(job_opt)
    j_opt.merge!(job_type: :worker, fatal: false)
    job_list =
      services.map { |service|
        LookupJob.perform_later(service, request, j_opt)&.job_id or
          Log.warn("#{meth}: #{service}: job failed")
      }.compact

    # Await task completions.
    job_table = ApplicationJob::Table.new(job_list)
    notifications_subscribe do |_, _, _, _, event_payload|
      # Because this block will be invoked upon completion of any GoodJob job,
      # only pay attention to the completion of a job that was started by this
      # waiter instance.
      data   = event_payload&.dig(:result)&.try(:value)
      job_id = data&.dig(:active_job_id)
      if job_table.include?(job_id)
        w_opt = { job_id: job_id, waiter_id: waiter_id, **job_opt, **opt }
        # noinspection RubyMismatchedArgumentType
        if (result = worker_task_completion(job_table, data, request, **w_opt))
          notifications_unsubscribe
          record.update(output: result)
          LookupChannel.lookup_response(result, **opt)
        end
      end
    end

    payload
  end

  # Update the appropriate *job_table* entry and if all jobs spawned by this
  # waiter have completed then send the final response back to the client.
  #
  # @param [ApplicationJob::Table]  job_table
  # @param [Hash]                   data
  # @param [LookupService::Request] request
  # @param [Hash]                   opt
  #
  # @return [LookupChannel::LookupResponse]   If all tasks have completed.
  # @return [nil]                             If worker task(s) are pending.
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def worker_task_completion(job_table, data, request, **opt)
    job_opt   = opt.extract!(:job_id, :waiter_id, *JOB_OPT)
    job_id    = job_opt[:job_id]
    timeout   = job_opt[:timeout]
    start     = job_opt[:start]    || timestamp
    deadline  = job_opt[:deadline] || timeout && (start + timeout)

    # Update the table with information about the completed job.
    finish    = timestamp
    overtime  = deadline && past_due(deadline, finish)
    job_table[job_id] = data.except(:active_job_id)
    job_table[job_id][:late] ||= overtime if overtime

    # If there are still jobs spawned by this waiter then keep waiting.
    return unless job_table.all_completed?

    # If all jobs spawned by this waiter have completed then send the final
    # response back to the client.
    cnt, err  = job_table.summarize.values_at(:total, :error)
    waiter_id = job_opt[:waiter_id]
    job_type  = job_opt[:job_type] || :waiter
    status    = overtime ? :timeout : :complete

    LookupChannel::LookupResponse.new(**opt).tap do |rsp|
      rsp[:count]      = cnt
      rsp[:data]       = LookupService.merge_data(job_table, request)
      rsp[:discard]    = err if err
      rsp[:job_id]     = waiter_id
      rsp[:job_type]   = job_type
      rsp[:service]    = job_table.result_values(:service).flatten.uniq
      rsp[:status]     = JOB_STATUS.dig(job_type, status) || '???'
      rsp[:start_time] = start
      rsp[:end_time]   = finish
      rsp[:duration]   = finish - start
    end

  rescue => error
    __output "JOB ERROR: #{__method__}: #{error.full_message}"
    raise error
  end

end

__loading_end(__FILE__)
