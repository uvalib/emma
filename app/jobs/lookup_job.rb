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
  # @option argument[2] [Boolean] :no_raise
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
    no_raise = record = nil
    super
    args     = arguments.dup
    opt      = args.extract_options!.dup
    no_raise = opt.delete(:no_raise)
    meth     = opt[:meth]  ||= "#{self.class}.#{__method__}"
    start    = opt[:start] ||= timestamp
    timeout  = opt[:timeout]

    service  = args.shift.presence or raise ExecError, "#{meth}: no service"
    request  = args.shift.presence or raise ExecError, "#{meth}: no request"
    record   = JobResult.create(active_job_id: job_id)

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

  JOB_TYPES   = JOB_STATUS.keys.freeze

  JOB_OPTIONS = %i[meth start status timeout deadline job_type].freeze

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
    job_opt  = opt.extract!(*JOB_OPTIONS)
    meth     = job_opt[:meth]     || __method__
    start    = job_opt[:start]    || timestamp
    status   = job_opt[:status]
    timeout  = job_opt[:timeout]
    deadline = job_opt[:deadline] || (timeout && (start + timeout))
    job_type = job_opt[:job_type] || :worker

    # Perform lookup on the external service.
    response =
      LookupService.get_from(service, request).tap do |rsp|
        # noinspection RubyMismatchedArgumentType
        overtime = deadline && past_due(deadline)
        status   = :late if overtime
        status ||= :done
        rsp[:class]    = rsp.class.name
        rsp[:job_id]   = job_id
        rsp[:job_type] = job_type
        rsp[:late]     = overtime if overtime
        rsp[:status]   = JOB_STATUS.dig(job_type, status) || '???'
      end
    result = response.to_h
    error  = response.error
    diag   = response.diagnostic

    # Report results.
    __debug_job(meth, 'OUTPUT') { result }
    record.update(output: result, error: error, diagnostic: diag)
    LookupChannel.lookup_response(result, **opt) if WORKER_RESPONSE

    # Add out-of-band identification data for the caller.
    result.merge!(active_job_id: job_id)
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
    job_opt   = opt.extract!(*JOB_OPTIONS)
    timeout   = job_opt.delete(:timeout)
    meth      = job_opt[:meth]     ||= __method__
    start     = job_opt[:start]    ||= timestamp
    deadline  = job_opt[:deadline] ||= timeout && (start + timeout)
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
    job_opt.merge!(job_type: :worker, no_raise: true)
    job_opt[:stream_name] = opt[:stream_name]
    job_list =
      services.map { |service|
        LookupJob.perform_later(service, request, job_opt)&.job_id or
          Log.warn("#{meth}: #{service}: job failed")
      }.compact

    # Await task completions.
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
        finish = timestamp
        # noinspection RubyMismatchedArgumentType
        overtime = deadline && past_due(deadline, finish)
        job_table[job_id] = data.except(:active_job_id)
        job_table[job_id][:late] ||= overtime if overtime

        # If all jobs spawned by this waiter have completed then send the
        # final response back to the client and remove this waiter instance
        # from the list of event subscribers.
        if job_table.completed?
          notifications_unsubscribe
          total, error = job_table.summarize.values_at(:total, :error)
          from   = job_table.result_values(:service).flatten.uniq
          status = overtime ? :timeout : :complete
          result =
            LookupChannel::LookupResponse.new(**opt).tap { |rsp|
              rsp[:count]      = total
              rsp[:data]       = LookupService.merge_data(job_table, request)
              rsp[:discard]    = error if error
              rsp[:job_id]     = waiter_id
              rsp[:job_type]   = job_type
              rsp[:service]    = from
              rsp[:status]     = JOB_STATUS.dig(job_type, status) || '???'
              rsp[:start_time] = start
              rsp[:end_time]   = finish
              rsp[:duration]   = finish - start
            }.compact_blank!
          record.update(output: result)
          LookupChannel.lookup_response(result, **opt)
        end
      end
    end

    payload
  end

end

__loading_end(__FILE__)
