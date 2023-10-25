# config/initializers/active_job.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for ActiveJob.

ActiveJob::Base.logger =
  Log.new(progname: 'JOB', level: (DEBUG_JOB ? Log::DEBUG : Log::INFO))
