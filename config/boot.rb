# config/boot.rb
#
# warn_indent:           true

# =============================================================================
# Initial console/log message before the normal boot sequence.
# =============================================================================

# For use within initialization code to branch between code that is intended
# for the Rails application versus code that is run in other contexts (e.g.,
# rake).
#
def running_rails_application?
  return false unless defined?(APP_PATH)
  return true  if ENV['IN_PASSENGER']
  return true  if $0.start_with?('spring app')
  return false unless $0.end_with?('rails') || $0.end_with?('spring')
  $*.include?('server')
end

# The time that the application was started.  This value is available globally.
BOOT_TIME = Time.now

STDERR.puts "@@@ $0 = #{$0.inspect}" # TODO: debugging - remove
STDERR.puts "@@@ $* = #{$*.inspect}" # TODO: debugging - remove
STDERR.puts "@@@ $ARGV = #{$ARGV.inspect}" # TODO: debugging - remove
STDERR.puts "@@@ APP_PATH = #{APP_PATH.inspect}" if defined?(APP_PATH) # TODO: debugging - remove
STDERR.puts "@@@ ENV = #{ENV.inspect}" # TODO: debugging - remove

if running_rails_application?
  STDERR.puts "boot @ #{BOOT_TIME}"
elsif !$0.end_with?('rake')
  STDERR.puts "Running #{$0.inspect}" unless $0.end_with?('rake')
end

# =============================================================================
# BOOT
# =============================================================================

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

STDERR.puts 'Starting Rails...' if running_rails_application?
