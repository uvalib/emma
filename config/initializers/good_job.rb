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

GoodJob.logger          = Log.new(progname: 'JOBS')
GoodJob.logger.level    = DEBUG_JOB ? Log::DEBUG : Log::INFO
GoodJob.on_thread_error = ->(e) { Log.error("#{e.class}: #{e.message}") }

# =============================================================================
# GoodJob::Configuration
# @see https://github.com/bensheldon/good_job#configuration-options
# @see https://github.com/bensheldon/good_job#cron-style-repeatingrecurring-jobs
# =============================================================================

# noinspection RubyResolve
Rails.application.config.good_job = {
  execution_mode:
    ENV['GOOD_JOB_EXECUTION_MODE']&.to_sym || :async,
  poll_interval:
    ENV['GOOD_JOB_POLL_INTERVAL']&.to_f || (application_deployed? ? 1.0 : 0.25),
  enable_cron: true,
  cron: {
    session_cleanup: {
      cron: '0 0 * * *',
      class: "SessionCleanupJob",
      description: "Every day run rake db:sessions:trim"
    }
  }
# max_threads:
#   # NOTE: must be set from config/env_vars.rb
# queue_string:
#   ENV['GOOD_JOB_QUEUES']                    || '*',
# poll_interval:
#   ENV['GOOD_JOB_POLL_INTERVAL']             || 10,
# max_cache:
#   ENV['GOOD_JOB_MAX_CACHE']                 || 10_000,
# shutdown_timeout:
#   ENV['GOOD_JOB_SHUTDOWN_TIMEOUT']          || -1,
# enable_cron:
#   ENV['GOOD_JOB_ENABLE_CRON']               || false,
# cron: # @see https://github.com/bensheldon/good_job#cron-style-repeatingrecurring-jobs
#   ENV['GOOD_JOB_CRON']                      || {},
# cleanup_preserved_jobs_before_seconds_ago:
#   ENV['GOOD_JOB_CLEANUP_PRESERVED_JOBS_BEFORE_SECONDS_AGO'] || 14.days.to_i,
# cleanup_interval_jobs:
#   ENV['GOOD_JOB_CLEANUP_INTERVAL_JOBS']     || 1_000,
# cleanup_interval_seconds:
#   ENV['GOOD_JOB_CLEANUP_INTERVAL_SECONDS']  || 10.minutes.to_i,
# daemonize:
#   false,
# pidfile:
#   ENV['GOOD_JOB_PIDFILE'] || Rails.root.join('tmp/pids/good_job.pid'),
# probe_port:
#   ENV['GOOD_JOB_PROBE_PORT'],
}
