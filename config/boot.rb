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
BOOT_TIME = Time.now.freeze

# The TeamCity build version.
#
# If there is (erroneously) more than one "buildtag.*" file, the build numbers
# will be listed separated by commas.
#
# @type [String]
#
BUILD_VERSION =
  Dir['buildtag.*'].map { _1.to_s.sub(/^.*buildtag\./, '') }.join(',')
    .tap { _1.replace('unknown') if _1.empty? }.freeze

# The base URL for the production system deployment.
#
# @type [String]
#
PRODUCTION_URL = ENV['PRODUCTION_URL'] ||= 'https://emma.lib.virginia.edu'

# The base URL for the staging system deployment.
#
# @type [String]
#
STAGING_URL = ENV['STAGING_URL'] ||= 'https://emma-dev.lib.virginia.edu'

# This constant is defined to mark sections of code that are present only to
# give context information to RubyMine -- for example, "include" statements
# which allow RubyMine to indicate which methods are overrides.
#
# (This constant is required to be a non-false value.)
#
ONLY_FOR_DOCUMENTATION = true

# =============================================================================
# Support methods
# =============================================================================

public

# Controls whether '0' and '1' are interpreted as boolean values for URL
# parameters or ENV setting values.
#
# @type [Boolean]
#
# @note Setting this to *true* may yield unexpected results.
#
BOOL_DIGIT = false

# @private
BOOL_DIGITS = %w[0 1].freeze

# @private
FALSE_DIGIT, TRUE_DIGIT = (BOOL_DIGITS if BOOL_DIGIT)

# Text values which represent *true*.
#
# @type [Array<String>]
#
TRUE_VALUES = ['true', 'yes', 'on', TRUE_DIGIT].compact.freeze

# Text values which represent *false*.
#
# @type [Array<String>]
#
FALSE_VALUES = ['false', 'off', 'no', FALSE_DIGIT].compact.freeze

# Indicate whether the item represents an explicit *true* value.
#
# @param [any, nil] value             Boolean, String, Symbol
#
def true?(value)
  case (arg = value)
    when String then value = value.strip.downcase
    when Symbol then value = value.to_s.downcase
  end
  case value
    when true, false  then value
    when *TRUE_VALUES then true
    when *BOOL_DIGITS then Log.warn { "true?(#{arg.inspect}) never bool" }
  end || false
end

# Indicate whether the item represents an explicit *false* value.
#
# @param [any, nil] value             Boolean, String, Symbol
#
def false?(value)
  case (arg = value)
    when String then value = value.strip.downcase
    when Symbol then value = value.to_s.downcase
  end
  case value
    when true, false   then !value
    when *FALSE_VALUES then true
    when *BOOL_DIGITS  then Log.warn { "false?(#{arg.inspect}) never bool" }
  end || false
end

# Produce JSON for use with "assets.js.erb".
#
# @param [any, nil] arg               String, Hash, Array
#
# @return [String]
#
# @see file:app/assets/javascripts/shared/decode.js *decodeJSON()*
#
def js(arg)
  if arg.is_a?(String)
    result = arg.strip
  else
    result = arg.to_json.gsub(/\\n"([,\]}])/, '"\1')
  end
  result.gsub!('\u003e', '>') # Undo JSONGemEncoder::ESCAPED_CHARS
  result.gsub!('\u003c', '<') # Undo JSONGemEncoder::ESCAPED_CHARS
  result.gsub!('\u0026', '&') # Undo JSONGemEncoder::ESCAPED_CHARS
  result.gsub!(/\n/,     '\n')
  result.gsub!(/'/,      '%27')
  result.gsub!(/\\"/,    '%5C%22')
  result
end

# Interpret *arg* as a regular expression, either as "/abc/" or "%r{abc}", or
# as an inspection of a Regexp like "(?-mix:abc)".
#
# @param [any, nil] arg               String or Regexp
#
# @return [Regexp, nil]
#
def regexp(arg)
  return arg if arg.is_a?(Regexp)
  return unless arg.is_a?(String)
  src = opt = nil
  case arg.strip
    when %r{^/(.*)/$}                 then src = $1
    when /^%r{(.*)}$/                 then src = $1
    when /^%r\((.*)\)$/               then src = $1
    when /^%r\[(.*)\]$/               then src = $1
    when /^\(\?([-mix]{3,4}):(.*)\)$/ then src, opt = $2, $1
  end
  src = src.gsub(%r{\\\\/}, '/') if src && opt
  src = src.gsub(/\\\\/, '\\')   if src && opt
  opt = opt.split('-').first     if opt
  Regexp.new(src, opt)           if src
end

# Interpret *arg* as an IP address range.
#
# Addresses with octets of "0" are translated into CIDR block form.
#
# @param [IPAddr,String,nil] arg
#
# @return [IPAddr, nil]
#
def ip_range(arg)
  return arg if arg.nil? || arg.is_a?(IPAddr)
  return if (arg = arg.to_s.strip).blank?
  case arg
    when /\.0\.0\.0$/ then IPAddr.new("#{arg}/8")
    when /\.0\.0$/    then IPAddr.new("#{arg}/16")
    when /\.0$/       then IPAddr.new("#{arg}/24")
    else                   IPAddr.new(arg)
  end
rescue IPAddr::InvalidAddressError
  nil
end

# =============================================================================
# Global properties
# =============================================================================

public

# Carrier for global property values which remain constant during execution.
#
#--
# noinspection RubyTooManyInstanceVariablesInspection
#++
module ExecutionProperty

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  INFO_ARGS = %w[-h -H --help -D --describe -T --tasks -n --dry-run].freeze

  attr_writer :application_deployed
  attr_writer :aws_deployment
  attr_writer :application_deployment
  attr_writer :production_deployment
  attr_writer :staging_deployment
  attr_writer :in_debugger
  attr_writer :in_local_docker
  attr_writer :in_rails
  attr_writer :in_rake
  attr_writer :non_test_rails
  attr_writer :sanity_check

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this is a deployed instance.
  #
  def application_deployed?
    return @application_deployed unless @application_deployed.nil?
    @application_deployed =
      !!ENV['AWS_DEFAULT_REGION'] || !'local'.casecmp?(ENV['DEPLOYMENT'])
  end

  # Indicate whether this is a desktop instance.
  #
  def not_deployed?
    !application_deployed?
  end

  # The true deployment type.
  #
  # @return [Symbol]
  #
  def aws_deployment
    return @aws_deployment unless @aws_deployment.nil?
    @aws_deployment = application_deployed? ? :production : :staging
  end

  # The deployment type.  Desktop development should use 'staging' resources.
  #
  # @return [Symbol]
  #
  # @see https://gitlab.com/uvalib/terraform-infrastructure/-/blob/master/emma.lib.virginia.edu/ecs-tasks/production/environment.vars
  # @see https://gitlab.com/uvalib/terraform-infrastructure/-/blob/master/emma.lib.virginia.edu/ecs-tasks/staging/environment.vars
  #
  def application_deployment
    return @application_deployment unless @application_deployment.nil?
    @application_deployment =
      ENV['DEPLOYMENT']&.downcase&.to_sym || aws_deployment
  end

  # Indicate whether this is the production service instance.
  #
  def production_deployment?
    return @production_deployment unless @production_deployment.nil?
    @production_deployment = (application_deployment == :production)
  end

  # Indicate whether this is the staging service instance.
  #
  def staging_deployment?
    return @staging_deployment unless @staging_deployment.nil?
    @staging_deployment =
      application_deployed? && (application_deployment == :staging)
  end

  # Indicate whether this instance is being run from the interactive debugger.
  #
  # === Usage Notes
  # For interactive debugging RubyMine uses 'ruby-debug-ide'.
  #
  def in_debugger?
    return @in_debugger unless @in_debugger.nil?
    @in_debugger = !!ENV['DEBUGGER_STORED_RUBYLIB']
  end

  # Indicate whether this instance is being run from a Docker container on a
  # development machine.
  #
  def in_local_docker?
    return @in_local_docker unless @in_local_docker.nil?
    @in_local_docker = (ENV['USER'] == 'docker') && not_deployed?
  end

  # For use within initialization code to branch between code that is intended
  # for the Rails application versus code that is run in other contexts (e.g.,
  # rake).
  #
  def rails_application?
    return @in_rails unless @in_rails.nil?
    v   = (ENV['RUBYMINE_CONFIG'] == 'rails') # desktop only
    v ||= !!ENV['IN_PASSENGER']
    v ||= $0.to_s.start_with?('spring app')
    v ||= $0.to_s.end_with?('rails', 'spring') &&
          $*.intersect?(%w[-b -p server runner])
    v &&= !$*.intersect?(INFO_ARGS)
    v &&= !!defined?(APP_PATH) unless ENV['RAILS_ENV'] == 'test'
    @in_rails = v
  end

  # Indicate whether this instance is being run as "rake" or "rails" with a
  # Rake task argument.
  #
  def rake_task?
    return @in_rake unless @in_rake.nil?
    v   = (ENV['RUBYMINE_CONFIG'] == 'rake') # desktop only
    v ||= $0.to_s.end_with?('rake')
    v ||= $0.to_s.end_with?('rails') && !rails_application? &&
          !$*.reject { _1.match(/^(-.*|new|console|generate)$/) }.empty?
    v &&= !$*.intersect?(INFO_ARGS)
    @in_rake = v
  end

  # Indicate whether this is the Rails application not under test.
  #
  def non_test_rails?
    return @non_test_rails unless @non_test_rails.nil?
    @non_test_rails = rails_application? && (ENV['RAILS_ENV'] != 'test')
  end

  # Indicate whether desktop-only validations are appropriate.
  #
  def sanity_check?
    return @sanity_check unless @sanity_check.nil?
    @sanity_check =
      non_test_rails? && not_deployed? && !false?(ENV['SANITY_CHECK'])
  end

end

class Object

  ExecutionProperty.instance_methods(false).each do |method|
    define_method(method) { ExecutionProperty.send(method) }
  end

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include ExecutionProperty
    extend  ExecutionProperty
  end
  # :nocov:

end

# =============================================================================
# Environment variables
# =============================================================================

require_relative 'env_vars'

# =============================================================================
# Pre-startup output.
# =============================================================================

# Load order has to be strictly controlled to allow Zeitwerk loading; this is
# incompatible with lazy-loading so support for "development" had to be
# abandoned.
if ENV['RAILS_ENV'] == 'development'
  raise %q(RAILS_ENV="development" disallowed; lazy-loading not supportable)
end

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

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Set up gems listed in the Gemfile.
require 'bundler/setup'

# Set up bootsnap caching on the desktop.
if not_deployed?
  ENV['BOOTSNAP_CACHE_DIR'] = CACHE_DIR
  require 'bootsnap/setup'
end

STDERR.puts "Starting #{ENV['RAILS_ENV']} Rails..." if rails_application?
