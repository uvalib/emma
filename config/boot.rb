# config/boot.rb
#
# frozen_string_literal: true
# warn_indent:           true

# =============================================================================
# Global constants
# =============================================================================

public

# The time that the application was started.
#
# @type [Time]
#
BOOT_TIME = Time.now

# The TeamCity build version.
#
# If there is (erroneously) more than one "buildtag.*" file, the build numbers
# will be listed separated by commas.
#
# @type [String]
#
BUILD_VERSION =
  Dir['buildtag.*'].map { |name| name.to_s.sub(/^.*buildtag\./, '') }.join(',')
    .tap { |result| result.replace('unknown') if result.empty? }

# For use by the application in desktop (non-deployed) testing.
#
# @type [String]
#
PRODUCTION_BASE_URL = 'https://emma.lib.virginia.edu'

# For use by the application in desktop (non-deployed) testing.
#
# @type [String]
#
STAGING_BASE_URL = 'https://emmadev.internal.lib.virginia.edu'

# =============================================================================
# Support methods
# =============================================================================

public

# Text values which represent *true*.
#
# @type [Array<String>]
#
TRUE_VALUES  = %w(1 yes true on).freeze

# Text values which represent *false*.
#
# @type [Array<String>]
#
FALSE_VALUES = %w(0 no false off).freeze

# Indicate whether the item represents an explicit *true* value.
#
# @param [Any, nil] value
#
def true?(value)
  return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
  return false unless value.is_a?(String) || value.is_a?(Symbol)
  TRUE_VALUES.include?(value.to_s.strip.downcase)
end

# Indicate whether the item represents an explicit *false* value.
#
# @param [Any, nil] value
#
def false?(value)
  return !value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
  return false  unless value.is_a?(String) || value.is_a?(Symbol)
  FALSE_VALUES.include?(value.to_s.strip.downcase)
end

# Produce JSON for use with "assets.js.erb".
#
# @param [String, Hash, Array, Any, nil] arg
#
# @return [String]
#
# @see file:app/assets/javascripts/shared/decode.js *decodeJSON()*
#
def js(arg)
  result = arg.is_a?(String) ? arg : arg.to_json
  result.gsub(/\\"/, '%5C%22')
end

# =============================================================================
# Global properties
# =============================================================================

public

# Indicate whether this is a deployed instance.
#
def application_deployed?
  !!ENV['AWS_DEFAULT_REGION'] || !ENV['DEPLOYMENT'].to_s.casecmp?('local')
end

# The true deployment type.
#
# @return [Symbol]
#
def aws_deployment
  application_deployed? ? :production : :staging
end

# The deployment type.  Desktop development should use 'staging' resources.
#
# @return [Symbol]
#
# @see https://gitlab.com/uvalib/terraform-infrastructure/-/blob/master/emma.lib.virginia.edu/ecs-tasks/production/environment.vars
# @see https://gitlab.com/uvalib/terraform-infrastructure/-/blob/master/emma.lib.virginia.edu/ecs-tasks/staging/environment.vars
#
def application_deployment
  ENV['DEPLOYMENT']&.downcase&.to_sym || aws_deployment
end

# Indicate whether this is the production service instance.
#
def production_deployment?
  application_deployment == :production
end

# Indicate whether this is the staging service instance.
#
def staging_deployment?
  application_deployed? && (application_deployment == :staging)
end

# Indicate whether this is a development-build instance.
#
def development_build?
  ENV['RAILS_ENV'] != 'production'
end

# Indicate whether this instance is being run from the interactive debugger.
#
# == Usage Notes
# For interactive debugging RubyMine uses 'ruby-debug-ide'.
#
def in_debugger?
  !!ENV['DEBUGGER_STORED_RUBYLIB']
end

# Indicate whether this instance is being run from a Docker container on a
# development machine.
#
def in_local_docker?
  (ENV['USER'] == 'docker') && !application_deployed?
end

# For use within initialization code to branch between code that is intended
# for the Rails application versus code that is run in other contexts (e.g.,
# rake).
#
def rails_application?
  if !defined?(@in_rails) || @in_rails.nil?
    @in_rails   = (ENV['RUBYMINE_CONFIG'] == 'rails') # desktop only
    @in_rails ||= !!ENV['IN_PASSENGER']
    @in_rails ||= $0.to_s.start_with?('spring app')
    @in_rails ||= $0.to_s.end_with?('rails', 'spring') &&
                  $*.any? { |arg| %w(-b -p server runner).include?(arg) }
    @in_rails &&= !!defined?(APP_PATH)
    @in_rails &&=
      !%w(-h -H --help -D --describe -T --tasks -n --dry-run).intersect?($*)
  end
  @in_rails
end

# Indicate whether this instance is being run as "rake" or "rails" with a Rake
# task argument.
#
def rake_task?
  if !defined?(@in_rake) || @in_rake.nil?
    @in_rake   = (ENV['RUBYMINE_CONFIG'] == 'rake') # desktop only
    @in_rake ||= $0.to_s.end_with?('rake')
    @in_rake ||= $0.to_s.end_with?('rails') && !rails_application? &&
      !$*.reject { |arg| arg.match(/^(-.*|new|console|generate)$/) }.empty?
    @in_rake &&=
      !%w(-h -H --help -D --describe -T --tasks -n --dry-run).intersect?($*)
  end
  @in_rake
end

# =============================================================================
# Environment variables
# =============================================================================

require_relative 'env_vars'

# =============================================================================
# Pre-startup output.
# =============================================================================

if rails_application?

  # Initial console/log message before the normal application boot sequence.
    STDERR.puts "boot @ #{BOOT_TIME}"
  if File.exist?((desktop_file = '../emma-production-deploy/tags/emma.tag'))
    STDERR.puts 'BUILD %s (latest)' % File.read(desktop_file).strip.inspect
  else
    STDERR.puts "BUILD #{BUILD_VERSION.inspect}"
  end

  # Log initial conditions.
  if application_deployed?
    STDERR.puts "$0       = #{$0.inspect}"
    STDERR.puts "$*       = #{$*.inspect}"
    STDERR.puts "$ARGV    = #{$ARGV.inspect}"
    STDERR.puts "APP_PATH = #{APP_PATH.inspect}" if defined?(APP_PATH)
    STDERR.puts "ENV:\n" +
      ENV.inspect
        .sub(/\A\s*{\s*/, '')
        .sub(/\s*}\s*\z/, '')
        .split(/",\s+/)
        .sort
        .join(%Q(",\n))
        .gsub(/"([^"]+)"=>/, '... \1 = ')
  end

  # API versions are usually in sync.
  unless (vs = SEARCH_API_VERSION) == (vi = INGEST_API_VERSION)
    STDERR.puts "** NOTE ** Search API v#{vs} != Ingest API v#{vi}"
  end

elsif !$0.to_s.end_with?('rails', 'rake')

  # Announce atypical executions (like irb or pry).
  STDERR.puts "Running #{$0.inspect}"

elsif $*.include?('assets:precompile')

  # Report on run time for 'rake assets:precompile'.
  at_exit do
    elapsed_time = Time.now - BOOT_TIME
    STDERR.puts("\nRun time: %0.2g seconds" % elapsed_time)
  end

end

# =============================================================================
# BOOT
# =============================================================================

# noinspection RubyMismatchedArgumentType
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' unless application_deployed?

STDERR.puts 'Starting Rails...' if rails_application?
