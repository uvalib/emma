# config/initializers/good_job.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for 'GoodJob'.
#
# @see https://github.com/bensheldon/good_job

# =============================================================================
# GoodJob class attributes
# @see https://github.com/bensheldon/good_job#global-options
# =============================================================================

GoodJob.preserve_job_records      = DEBUG_JOB             # Default: *true*
#GoodJob.retry_on_unhandled_error = application_deployed? # Default: *false*

GoodJob.logger = Log.new(progname: 'GJOB', level: ActiveJob::Base.logger.level)
GoodJob.on_thread_error = ->(e) { Log.error("#{e.class}: #{e.message}") }

# =============================================================================
# GoodJob::Configuration
# @see https://github.com/bensheldon/good_job#configuration-options
# @see https://github.com/bensheldon/good_job#cron-style-repeatingrecurring-jobs
# =============================================================================

# A mapping of environment variable name to `Rails.application.config.good_job`
# configuration key.
#
# @type [Hash{String=>Symbol}]
#
# @see "en.emma.env_var._good_job"
#
#--
# noinspection LongLine
#++
GOOD_JOB_ENV_KEY_MAP = {
  # ENV variable                                      # Configuration key                         # Default value
  # ------------------------------------------------- # ----------------------------------------- # ------------------------
  GOOD_JOB_CLEANUP_DISCARDED_JOBS:                    :cleanup_discarded_jobs,                    # true
  GOOD_JOB_CLEANUP_INTERVAL_JOBS:                     :cleanup_interval_jobs,                     # 1,000 job executions
  GOOD_JOB_CLEANUP_INTERVAL_SECONDS:                  :cleanup_interval_seconds,                  # 10 minutes
  GOOD_JOB_CLEANUP_PRESERVED_JOBS_BEFORE_SECONDS_AGO: :cleanup_preserved_jobs_before_seconds_ago, # 14 days
  GOOD_JOB_CRON:                                      :cron,                                      # {}
  GOOD_JOB_ENABLE_CRON:                               :enable_cron,                               # false
  GOOD_JOB_ENABLE_LISTEN_NOTIFY:                      :enable_listen_notify,                      # true
  GOOD_JOB_EXECUTION_MODE:                            :execution_mode,
  GOOD_JOB_IDLE_TIMEOUT:                              :idle_timeout,                              # nil seconds (no timeout)
  GOOD_JOB_MAX_CACHE:                                 :max_cache,                                 # 10,000 scheduled jobs
  GOOD_JOB_MAX_THREADS:                               :max_threads,                               # 5
  GOOD_JOB_PIDFILE:                                   :pidfile,                                   # 'tmp/pids/good_job.pid'
  GOOD_JOB_POLL_INTERVAL:                             :poll_interval,                             # 10 seconds
  GOOD_JOB_QUEUES:                                    :queues,                                    # '*'
  GOOD_JOB_QUEUE_SELECT_LIMIT:                        :queue_select_limit,                        # nil (no limit)
  GOOD_JOB_SHUTDOWN_TIMEOUT:                          :shutdown_timeout,                          # -1 seconds (forever)
}.stringify_keys.freeze

Rails.application.configure do

  testing = Rails.env.test? || in_debugger?

  false_or_integer = ->(val) {
    case
      when true?(val)  then nil
      when false?(val) then false
      else                  val&.to_i
    end
  }

  # noinspection RubyResolve, LongLine
  config.good_job =
    GOOD_JOB_ENV_KEY_MAP.map { |val, key|
      val = ENV_VAR[val]
      val =
        case key
          when :cleanup_discarded_jobs                    then !false?(val) unless val.nil?
          when :cleanup_interval_jobs                     then false_or_integer.(val)
          when :cleanup_interval_seconds                  then false_or_integer.(val)
          when :cleanup_preserved_jobs_before_seconds_ago then val&.to_i
          when :cron                                      then val
          when :enable_cron                               then !false?(val) unless testing
          when :enable_listen_notify                      then !false?(val) unless val.nil?
          when :execution_mode                            then val&.to_sym || (testing ? :inline : :async)
          when :idle_timeout                              then val&.to_i
          when :max_cache                                 then val&.to_i
          when :max_threads                               then nil # NOTE: must be set from config/env_vars.rb
          when :pidfile                                   then val&.presence
          when :poll_interval                             then val&.to_f || (application_deployed? ? 1.0 : 0.25 unless Rails.env.test?)
          when :queues                                    then val&.presence
          when :queue_select_limit                        then val&.to_i
          when :shutdown_timeout                          then val&.to_f
        end
      [key, val]
    }.to_h.compact

  # NOTE: Prevent GoodJob::Configuration#cron from re-parsing GOOD_JOB_CRON;
  #   this will have already been supplied from Configuration::EnvVar.
  ENV.delete('GOOD_JOB_CRON') unless ENV_VAR.from_env.key?('GOOD_JOB_CRON')

end
