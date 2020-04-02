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

# =============================================================================
# Support methods
# =============================================================================

public

# Text values which represent *true*.
#
# @type [Array<String>]
#
TRUE_VALUES  = %w(1 yes true).freeze

# Text values which represent *false*.
#
# @type [Array<String>]
#
FALSE_VALUES = %w(0 no false).freeze

# Indicate whether the item represents a true value.
#
# @param [Object] value
#
def true?(value)
  case value
    when TrueClass, FalseClass then value
    when Array, Hash, nil      then false
    else TRUE_VALUES.include?(value.to_s.strip.downcase)
  end
end

# Indicate whether the item represents a true value.
#
# @param [Object] value
#
def false?(value)
  case value
    when TrueClass, FalseClass then !value
    when Array, Hash, nil      then false
    else FALSE_VALUES.include?(value.to_s.strip.downcase)
  end
end

# =============================================================================
# Global properties
# =============================================================================

public

# Indicate whether this is a deployed instance.
#
def application_deployed?
  # !!ENV['AWS_DEFAULT_REGION']
  # !!ENV['AWS_EXECUTION_ENV']
  !!ENV['AWS_REGION']
end

# Indicate whether this instance is being run from the interactive debugger.
#
# == Usage Notes
# For interactive debugging RubyMine uses 'ruby-debug-ide'.
#
def in_debugger?
  !!ENV['DEBUGGER_STORED_RUBYLIB']
end

# For use within initialization code to branch between code that is intended
# for the Rails application versus code that is run in other contexts (e.g.,
# rake).
#
def rails_application?
  if !defined?(@in_rails) || @in_rails.nil?
    @in_rails = defined?(APP_PATH)
    @in_rails &&= $*.none? { |arg| %w(-h --help).include?(arg) }
    @in_rails &&= (
      !!ENV['IN_PASSENGER'] ||
      $0.start_with?('spring app') ||
      ($0.end_with?('rails', 'spring') && $*.include?('server'))
    )
  end
  @in_rails
end

# =============================================================================
# Initial console/log message before the normal boot sequence.
# =============================================================================

if rails_application?
  STDERR.puts "boot @ #{BOOT_TIME}"
  STDERR.puts "BUILD #{BUILD_VERSION.inspect}"
  if application_deployed? # TODO: debugging - remove section eventually
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
elsif !$0.end_with?('rails', 'rake')
  STDERR.puts "Running #{$0.inspect}"
end

# =============================================================================
# BOOT
# =============================================================================

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

STDERR.puts 'Starting Rails...' if rails_application?
