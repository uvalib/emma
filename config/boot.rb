# config/boot.rb
#
# frozen_string_literal: true
# warn_indent:           true

# =============================================================================
# Global constants
# =============================================================================

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
# Initial console/log message before the normal boot sequence.
# =============================================================================

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
# For interactive debugging RubyMine uses 'ruby-debug-ide', which is not
# currently compatible with the Zeitwerk loader.  For that reason, there are a
# few places in the code which require special handling based on this value.
#
def in_debugger?
  !!ENV['DEBUGGER_STORED_RUBYLIB']
end

# For use within initialization code to branch between code that is intended
# for the Rails application versus code that is run in other contexts (e.g.,
# rake).
#
def rails_application?
  return false unless defined?(APP_PATH)
  return false if $*.any? { |arg| %w(-h --help).include?(arg) }
  return true  if ENV['IN_PASSENGER']
  return true  if $0.start_with?('spring app')
  return false unless $0.end_with?('rails', 'spring')
  $*.include?('server')
end

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
