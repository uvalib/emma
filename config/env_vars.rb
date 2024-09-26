# config/env_vars.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Set key environment variables and global properties which must be available
# during the boot sequence.
#
# For all other global constants:
# @see lib/_constants.rb

require_relative 'boot'

# =============================================================================
# Remove blank environment variables
# =============================================================================

ENV.keys.each do |k|
  next unless ENV[k].is_a?(String)
  ENV[k] = ENV[k].strip
  ENV.delete(k) if ENV[k].empty?
end

# =============================================================================
# Configuration values for desktop-only deployments
# =============================================================================

in_rails = rails_application?

config =
  unless ENV['DEPLOYMENT']
    # If running from the desktop, load a project-specific script to provide
    # the environment variables that would have been set up from Terraform.

    './.idea/environment.rb'.then { _1 if File.exist?(_1) } ||

    # To acquire desktop environment values, the RubyMine Docker configuration
    # needs a "Bind Mount" with "/home/rwl/Work/emma/.idea:/mnt:ro"; i.e.:
    # "docker run --mount type=bind,src=/home/rwl/Work/.idea,dst=/mnt,readonly"

    '/mnt/environment.rb'.then { _1 if File.exist?(_1) && in_local_docker? }
  end

if config && require(config)
  $stderr.puts("DESKTOP ENVIRONMENT #{config.inspect}") if in_rails
end

# =============================================================================
# Database properties
# =============================================================================

if in_rails || (rake_task? && $*.any? { _1 =~ /^(db|emma|emma_data):/ })

  if ENV['DBHOST'] && ENV['DBPORT'] && ENV['DBUSER'] && ENV['DBPASSWD']

    # This condition won't hold from the deployed application using Terraform
    # "environment.vars", but it will for the specific case of the database
    # migration run within the uva-emma-production-deploy-codepipeline.

    ENV['DEPLOYMENT'] ||= 'production'

  else

    # DEPLOYMENT, DBNAME, DBUSER, and DBPASSWD must be defined in the Terraform
    # project within "emma.lib.virginia.edu/ecs-tasks/*/environment.vars" (or
    # in the "environment.rb" configuration script if running on the desktop).
    #
    # DBHOST and/or DBPORT *may* be defined there; if not, DATABASE *must* be
    # defined in order to derive the missing value(s).

    host_port_missing = !(ENV['DBHOST'] && ENV['DBPORT'])

    databases = %w[postgres mysql]
    database = type = nil
    case (d = ENV['DATABASE']&.downcase)
      when /^post/  then database, type = %w[postgres postgres]
      when /^mysql/ then database, type = %w[mysql standard]
      when nil      then raise 'missing ENV[DATABASE]' if host_port_missing
      else               raise "#{d.inspect} not in #{databases.inspect}"
    end
    database, type = %w[postgres postgres] unless database

    case database
      when 'mysql'
        ENV['DBPORT']   ||= '3306'
      when 'postgres'
        ENV['DBPORT']   ||= ENV['PGPORT'] || '5432'
        ENV['DBHOST']   ||= ENV['PGHOST']
        ENV['DBUSER']   ||= ENV['PGUSER']
        ENV['DBPASSWD'] ||= ENV['PGPASSWORD']
    end

    unless ENV['DBHOST']
      deployments = %w[production staging local]
      case (d = ENV['DEPLOYMENT']&.downcase)
        when /^prod/  then deployment = 'production'
        when /^stag/  then deployment = 'staging'
        when /^local/ then deployment = 'local'
        when nil      then raise 'missing ENV[DEPLOYMENT]'
        else               raise "#{d.inspect} not in #{deployments.inspect}"
      end
      ENV['DBHOST'] ||= 'localhost' if deployment == 'local'
      ENV['DBHOST'] ||= "rds-#{type}-#{deployment}.internal.lib.virginia.edu"
    end

  end

end

# =============================================================================
# Operational properties
# =============================================================================

# Serve files from the "/public" folder if *true*.
#
# @type [Boolean]
#
RAILS_SERVE_STATIC_FILES = !false?(ENV['RAILS_SERVE_STATIC_FILES'])

# Cache directory for the current execution environment.
#
# @note Currently this does not affect precompiled assets (tmp/cache/assets)
#   because extra work would be needed in lib/tasks to support selectively
#   updating public/assets according to the current execution environment.
#
# @type [String]
#
CACHE_DIR =
  [ENV['CACHE_DIR'], ENV['BOOTSNAP_CACHE_DIR'], 'tmp/cache']
    .compact.map(&:strip).reject(&:empty?).first.then { |path|
      path = path.delete_suffix('/')
      case ENV['RAILS_ENV']
        when 'development' then "#{path}-dev"
        when 'test'        then "#{path}-test"
        else                    path
      end
    }.freeze

# The value of RAILS_MAX_THREADS is adjusted here so that the additional
# requirements of ActionCable and the scheduler are taken into account before
# either config/database.yml or config/puma.rb are processed.
#
# * 1 connection dedicated to ActionCable for LISTEN/NOTIFY
# * 1 connection dedicated to the scheduler for LISTEN/NOTIFY
# * enough connections to cover the GoodJob query pool
# * (optional) 2 connections for the GoodJob cron scheduler
# * (optional) 1 connection per sub-thread if the application makes multi-
#   threaded queries within a job.
# * enough connections to cover the webserver when running GoodJob :async

ENV['RAILS_MAX_THREADS'] = [
  (ENV['RAILS_MAX_THREADS']    || 5),
  (ENV['GOOD_JOB_MAX_THREADS'] || 5),
  1, # When using the postgresql adapter in config/cable.yml.
].map!(&:to_i).sum.to_s

# =============================================================================
# Output
# =============================================================================

# Control console debugging output.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
CONSOLE_DEBUGGING = true?(ENV['CONSOLE_DEBUGGING'])

# Control console output.
#
# Normally __output (and __debug) are not displayed in non-Rails invocations of
# the code (e.g. rake, irb, etc) unless CONSOLE_DEBUGGING is *true*.
#
CONSOLE_OUTPUT = live_rails_application? || CONSOLE_DEBUGGING

# Control TRACE_* activation.
#
# By default, the TRACE_* constants are only active when the code is being run
# as a Rails application (i.e., not for "rake", "rails console", etc.).
#
TRACE_OUTPUT = live_rails_application? || true?(ENV['TRACE_RAKE'])

# Control tracking of file load order.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #__loading
#
TRACE_LOADING = TRACE_OUTPUT && true?(ENV['TRACE_LOADING'])

# Control tracking of invocation of Concern "included" blocks.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #__included
#
TRACE_CONCERNS = TRACE_OUTPUT && true?(ENV['TRACE_CONCERNS'])

# Control tracking of Rails notifications.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #NOTIFICATIONS
#
TRACE_NOTIFICATIONS = TRACE_OUTPUT && true?(ENV['TRACE_NOTIFICATIONS'])
