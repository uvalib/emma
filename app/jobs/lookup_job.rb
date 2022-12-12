# app/jobs/lookup_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class LookupJob < ActiveJob::Base

  include Emma::TimeMethods
  include Emma::Debug
  extend  Emma::Debug

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_enqueue do |job|
    __debug_job('--->>> ENQUEUE START') { job.inspect }
  end

  after_enqueue do |job|
    __debug_job('<<<--- ENQUEUE END')   { job.inspect }
  end

  before_perform do |job|
    __debug_job('--->>> PERFORM START') { job.inspect }
  end

  after_perform do |job|
    __debug_job('<<<--- PERFORM END')   { job.inspect }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # initialize
  #
  # @param [*] arguments              Assigned to ActiveJob::Core#arguments.
  #
  def initialize(*arguments)
    __debug_job(__method__) { { arguments: arguments } }
    super
  end

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
  # @option argument[2] [Symbol]  :role
  # @option argument[2] [Boolean] :no_raise
  #
  # @return [Hash]
  #
  #--
  # == Variations
  #++
  #
  # @overload perform_later(services, request, opt)
  #   The "waiter" task invoked via `LookupJob.perform_later`.
  #   @param [Array<Class,LookupService::RemoteService>]  services
  #   @param [LookupService::Request]                     request
  #   @param [Hash]                                       opt
  #   @return [Hash]
  #
  # @overload perform_later(service, request, opt, role: :worker)
  #   A "worker" task invoked from within #waiter_task.
  #   @param [Class,LookupService::RemoteService]         service
  #   @param [LookupService::Request]                     request
  #   @param [Hash]                                       opt
  #   @return [Hash]  From LookupService::RemoteService#lookup_metadata
  #
  def perform(*)
    no_raise = record = nil
    __debug_job(__method__) { { arguments: arguments } }
    meth     = "#{self.class}.#{__method__}"
    args     = arguments.dup
    opt      = args.extract_options!.dup
    no_raise = opt.delete(:no_raise)
    service  = args.shift.presence or raise ExecError, "#{meth}: no service"
    request  = args.shift.presence or raise ExecError, "#{meth}: no request"
    role     = opt.delete(:role)&.to_sym
    record   = JobResult.create(active_job_id: job_id)
    Log.warn("#{meth}: ignored args #{args.inspect}") if args.present?
    opt[:meth]     ||= meth
    opt[:start]    ||= timestamp
    opt[:deadline] ||= (opt[:start] + opt[:timeout]) if opt[:timeout]
    if role == :worker
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
    meth     = opt.delete(:meth)     || __method__
    start    = opt.delete(:start)    || timestamp
    status   = opt.delete(:status)
    timeout  = opt.delete(:timeout)
    deadline = opt.delete(:deadline) || (timeout && (start + timeout))

    # Perform lookup on the external service.
    response =
      LookupService.get_from(service, request).tap do |rsp|
        late   = deadline && positive_float(timestamp - deadline)
        status = late && :late || status || :done
        rsp[:status] = JOB_STATUS[:worker][status]
        rsp[:job_id] = job_id
        rsp[:late]   = late if late
      end
    result = response.to_h
    error  = response.error
    diag   = response.diagnostic

    # Report results.
    __debug_job("#{meth} OUTPUT") { result }
    record.update(output: result, error: error, diagnostic: diag)
    LookupChannel.lookup_response(result, **opt) if WORKER_RESPONSE

    # Add out-of-band identification data for the caller.
    result.merge!(active_job_id: job_id)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The instrumentation notification which causes the waiter task to update its
  # tally of results and send a response back to the client if all tasks have
  # either completed or timed-out.
  #
  # @type [String]
  #
  WAITER_NOTIFICATION = 'finished_job_task.good_job'

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
    local    = extract_hash!(opt, :meth, :start, :timeout, :deadline)
    meth     = local[:meth]     ||= __method__
    start    = local[:start]    ||= timestamp
    timeout  = local.delete(:timeout)
    deadline = local[:deadline] ||= timeout && (start + timeout)
    services = Array.wrap(services)

    # Send an initial response back to the client.
    payload  = {
      service: services.map(&:service_key),
      job_id:  job_id,
      data:    request
    }
    LookupChannel.lookup_initial_response(payload, **opt)

    # Spawn worker tasks.
    job_opt  = opt.merge(local, role: :worker, no_raise: true)
    job_list =
      services.map { |service|
        LookupJob.perform_later(service, request, job_opt)&.job_id or
          Log.warn("#{meth}: #{service}: job failed")
      }.compact
    job_data = Concurrent::Hash[job_list.map { |jid| [jid, nil] }]

    # Await task completions.
    ActiveSupport::Notifications.subscribe(WAITER_NOTIFICATION) do
      # @type [String] _event_name
      # @type [Time]   _event_start
      # @type [Time]   _event_finish
      # @type [String] _event_id
      # @type [Hash]   event_payload
      |_event_name, _event_start, _event_finish, _event_id, event_payload|
      data = event_payload&.dig(:result)&.try(:value)
      job  = data&.dig(:active_job_id)
      if job_data.key?(job)
        overtime      = deadline && positive_float(timestamp - deadline)
        job_data[job] = data.except(:active_job_id)
        job_data[job][:late] ||= overtime if overtime
        if job_data.values.none?(&:nil?)
          ActiveSupport::Notifications.unsubscribe(WAITER_NOTIFICATION)
          error  = []
          from   = []
          total  = 0
          job_data.each_pair do |j_id, j_result|
            error << j_id if j_result[:late] || j_result[:error]
            next if (j_items = j_result.dig(:data, :items)).blank?
            from  += Array.wrap(j_result[:service])
            total += (j_result[:count] ||= j_items.values.sum(&:size))
          end
          status = overtime ? :timeout : :complete
          result =
            LookupChannel::LookupResponse.new(**opt).tap { |rsp|
              rsp[:status]  = JOB_STATUS[:waiter][status]
              rsp[:service] = from.uniq
              rsp[:job_id]  = job_id
              rsp[:count]   = total
              rsp[:discard] = error if error.present?
              rsp[:data]    = LookupService.merge_data(job_data, request)
            }.compact_blank!
          record.update(output: result)
          LookupChannel.lookup_response(result, **opt)
        end
      end
    end

    payload
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  def __debug_job(*args, **opt)
    opt[:separator] ||= "\n\t"
    tid   = Thread.current.name
    name  = self.is_a?(Class) ? self.name : self.class.name
    args  = args.join(Emma::Debug::DEBUG_SEPARATOR)
    added = block_given? ? yield : {}
    __debug_items("#{name} #{args}", **opt) do
      added.is_a?(Hash) ? added.merge(thread: tid) : [*added, "thread #{tid}"]
    end
  end
    .tap { |meth| neutralize(meth) unless DEBUG_JOB }

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # @private
  # @type [Array<Symbol>]
  DATA_COLUMNS = %i[output error diagnostic].freeze

  # @private
  # @type [Symbol]
  # noinspection RubyMismatchedConstantType
  DEFAULT_DATA_COLUMN = DATA_COLUMNS.first

  # Extract job results from the 'job_results' database table.
  #
  # @param [String]                  job_id   The :active_job_id column value
  #                                             for the record to get.
  # @param [Symbol,String,nil]       column   The data column to get; default:
  #                                             #DEFAULT_DATA_COLUMN.
  # @param [Array,Symbol,String,nil] path     If provided, the path into the
  #                                             JSON hierarchy.
  #
  # @return [Hash]
  # @return [nil]                     If the requested data was not found.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def self.job_result(job_id:, column: nil, path: nil, **)
    column = column&.to_sym || DEFAULT_DATA_COLUMN
    # noinspection RubyMismatchedArgumentType
    raise "#{column}: invalid" unless DATA_COLUMNS.include?(column)

    result = JobResult.where(active_job_id: job_id).pluck(column).first
    return unless result.is_a?(Hash)

    type   = result[:class]&.to_s&.safe_constantize
    result = type.template.merge(result) if type&.respond_to?(:template)
    return result if path.blank?

    path = path.is_a?(Array) ? path.map(&:to_s) : path.to_s.split('/')
    result.dig(*path.compact_blank!)
  end

end

__loading_end(__FILE__)
