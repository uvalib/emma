# config/puma.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Only needed when running "yard server".
require_relative 'boot'

# =============================================================================
# Settings
# =============================================================================

# Puma settings from `ENV_VAR` for use in this file.
#
# @type [Hash{Symbol=>any}]
#
# @see Puma::Configuration#DEFAULTS
#
puma = {
  # Key                 # ENV variable                # Default
  # ------------------  # --------------------------  # ---------------------
  environment:          'RAILS_ENV',                  # -
  first_data_timeout:   'PUMA_FIRST_DATA_TIMEOUT',    # 30 seconds
  log_requests:         'PUMA_LOG_REQUESTS',          # -
  max_threads:          'RAILS_MAX_THREADS',          # 5
  min_threads:          'RAILS_MIN_THREADS',          # 0
  persistent_timeout:   'PUMA_PERSISTENT_TIMEOUT',    # 20 seconds
  pidfile:              'PIDFILE',                    # -
  port:                 'PORT',                       # -
  worker_timeout:       'PUMA_WORKER_TIMEOUT',        # 60 seconds
  workers:              'WEB_CONCURRENCY',            # 0
}.map { |key, var|
  next if (val = var && ENV_VAR[var]).nil?
  val =
    case key
      when :environment         then val.to_s
      when :first_data_timeout  then val.to_i
      when :log_requests        then true?(val)
      when :max_threads         then val.to_i
      when :min_threads         then val.to_i
      when :persistent_timeout  then val.to_i
      when :pidfile             then val.to_s
      when :port                then val.to_i
      when :worker_timeout      then val.to_i
      when :workers             then val.to_i
    end
  [key, val]
}.compact.to_h

# =============================================================================
# Default values
# =============================================================================

puma[:environment]  ||= 'production'
puma[:min_threads]  ||= puma[:max_threads]
puma[:port]         ||= ENV_VAR['PUMA_PORT']
puma[:worker_timeout] = nil unless in_debugger?

# =============================================================================
# Configuration
# =============================================================================

# Puma can serve each request in a thread from an internal thread pool.
#
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads puma[:min_threads], puma[:max_threads]

# Specify the `port` where Puma will receive requests; default is 3000.
#
port puma[:port]

# Inform Puma of the execution environment.
#
environment puma[:environment]

# Specify the file where Puma will note its process ID.
#
pidfile puma[:pidfile]

# Specify the number of `workers` to boot in clustered mode.
#
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers puma[:workers] if puma[:workers]

# Effectively avoid worker timeouts when running inside the debugger.
#
worker_timeout puma[:worker_timeout] if puma[:worker_timeout]

# Use the `preload_app!` method when specifying a `workers` number.
#
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Allow Puma to be restarted with the `rails restart` command.
plugin :tmp_restart

# Certain uploads seem to take Uppy a while to accumulate before it actually
# starts to send the request.
first_data_timeout puma[:first_data_timeout] if puma[:first_data_timeout]

# Larger uploads have been failing right at the end, so they may be pushing up
# against the default 20 second read timeout.
persistent_timeout puma[:persistent_timeout] if puma[:persistent_timeout]

# =============================================================================
# Logging
# =============================================================================

log_requests if puma[:log_requests]

if DEBUG_PUMA
  debug
  on_restart         { puts 'PUMA on_restart' }
  before_fork        { puts 'PUMA before_fork: starting workers' }
  on_worker_boot     { puts 'PUMA on_worker_boot' }
  on_worker_shutdown { puts 'PUMA on_worker_shutdown' }
  on_worker_fork     { puts 'PUMA on_worker_fork' }
  after_worker_fork  { puts 'PUMA after_worker_fork' }
  on_booted          { puts 'PUMA on_booted' }
  on_refork          { puts 'PUMA on_refork' }
  out_of_band        { puts 'PUMA worker idle' }
end

# =============================================================================
# Job scheduler
# =============================================================================

before_fork        { GoodJob.shutdown }
on_worker_boot     { GoodJob.restart }
on_worker_shutdown { GoodJob.shutdown }

MAIN_PID = Process.pid
at_exit { GoodJob.shutdown if Process.pid == MAIN_PID }
