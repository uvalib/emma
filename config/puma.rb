# config/puma.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Only needed when running "yard server".
require_relative 'boot'

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS', max_threads_count)
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is
# 3000.
#
port ENV.fetch('PORT', 3000)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV', 'development')

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch('WEB_CONCURRENCY', 2)

# Effectively avoid worker timeouts when running inside the debugger.
#
worker_timeout 3600 if in_debugger?

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Certain uploads seem to take Uppy a while to accumulate before it actually
# starts to send the request.
first_data_timeout 90 # seconds

# Larger uploads have been failing right at at the end, so they may be pushing
# up against the default 20 second read timeout.
persistent_timeout 300 # seconds

# =============================================================================
# Logging
# =============================================================================

if true?(ENV['PUMA_LOG_REQUESTS'])
  log_requests
end

if true?(ENV['DEBUG_PUMA'])
  debug
  before_fork        { puts 'PUMA before_fork: starting workers' }
  on_worker_boot     { puts 'PUMA on_worker_boot' }
  on_worker_shutdown { puts 'PUMA on_worker_shutdown' }
  on_worker_fork     { puts 'PUMA on_worker_fork' }
  after_worker_fork  { puts 'PUMA after_worker_fork' }
  on_refork          { puts 'PUMA on_refork' }
  out_of_band        { puts 'PUMA worker idle' }
end
