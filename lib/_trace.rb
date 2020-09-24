# lib/_trace.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Loader debugging.

# =============================================================================
# Constants
# =============================================================================

public

# Control console debugging output.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
CONSOLE_DEBUGGING = true?(ENV['CONSOLE_DEBUGGING'])

# Control console output.
#
# Normally __output (and __debug) are not displayed in IRB or other non-Rails
# invocations of the code.  The environment variable should normally be *false*
# ()or missing) in order to avoid extraneous output during rake, irb, etc.
#
CONSOLE_OUTPUT = rails_application? || CONSOLE_DEBUGGING

# Control tracking of file load order.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #__loading
#
TRACE_LOADING = true?(ENV['TRACE_LOADING'])

# Control tracking of invocation of Concern "included" blocks.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #__included
#
TRACE_CONCERNS = true?(ENV['TRACE_CONCERNS'])

# Control tracking of Rails notifications.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #NOTIFICATIONS
#
TRACE_NOTIFICATIONS = true?(ENV['TRACE_NOTIFICATIONS'])

# =============================================================================
# Module methods
# =============================================================================

public

# Replace method definitions.
#
# @param [Array<Symbol>] methods
#
def neutralize_methods(*methods)
  methods.compact.each { |m| eval("def #{m}(*); end") }
end

# =============================================================================
# Debugging - console output
# =============================================================================

require 'io/console'

# For AWS, add indentation prefix characters to help make debugging output
# stand out from normal Rails.logger entries.
CONS_INDENT = $stderr.isatty ? '' : '_   '

# Initial characters which mark a debug line.
DEBUG_LEADER = ''

# Truncate long debug output lines to this number of characters.
DEBUG_MAX = 2048

# Write indented line(s) to $stderr.
#
# @param [Array<Hash,Array,String,*>] args
#
# @option args.last [String]          :leader     At the start of each line.
# @option args.last [String, Integer] :indent     Default: #CONS_INDENT.
# @option args.last [String]          :separator  Default: "\n"
# @option args.last [Boolean]         :debug      Structure for debug output.
# @option args.last [Symbol, Integer, Boolean] :log   Note [1]
#
# @return [nil]
#
# @yield To supply additional items to output.
# @yieldreturn [Array<String>]
#
# == Notes
# [1] When deployed, this option will create a log entry rather than produce
# $stderr output.  If not deployed, the log entry is created in addition to
# $stderr output.
#
def __output(*args)
  return if defined?(Log) && Log.silenced?
  opt = args.extract_options!
  sep = opt[:separator] || "\n"

  # Construct the string that is prepended to each output line.
  indent = opt[:indent] || (sep.include?("\n") ? CONS_INDENT : '')
  indent = (' ' * indent if indent.is_a?(Integer) && (indent > 0))
  leader = "#{indent}#{opt[:leader]}"
  leader += ' ' unless (leader == indent.to_s) || leader.match?(/\s$/)

  # Combine arguments and block results into a single string.
  args += Array.wrap(yield) if block_given?
  if opt[:debug]
    omit = opt[:omission] || '…'
    max  = opt[:max]
    max  = max - leader.size if max
    args =
      args.flat_map { |arg|
        case arg
          when Hash   then arg.map { |k, v| "#{k} = #{v}" }
          when Array  then arg.map(&:to_s)
          when String then arg
          else             arg.inspect
        end
      }.map { |arg|
        if max
          next unless max.positive?
          size = arg.size + sep.size
          if max >= size
            max -= size
          else
            stop = max - omit.length
            arg  = (arg[0, stop] + omit unless stop.negative?)
            max  = 0
          end
        end
        arg
      }.compact
  end
  lines = leader + args.compact.join(sep).gsub(/\n/, "\n#{leader}").strip

  # For desktop builds, if explicitly requested, copy output to the log.
  unless (level = opt[:log]).blank? || application_deployed? || !defined?(Log)
    level = Log.log_level(level, :debug)
    Log.add(level, lines)
  end

  # Emit output.
  $stdout.flush
  $stderr.flush
  $stderr.puts(lines)
  $stderr.flush
  nil
end

# Write indented debug line(s) to $stderr.
#
# @param [Array] args                 Passed to #__output.
# @param [Proc]  block                Passed to #__output.
#
# @return [nil]
#
def __debug(*args, &block)
  # noinspection RubyNilAnalysis
  opt = args.extract_options!.merge(debug: true)
  opt[:leader]   ||= DEBUG_LEADER
  opt[:max]      ||= DEBUG_MAX
  opt[:omission] ||= '...'
  __output(*args, opt, &block)
end

neutralize_methods(:__output) unless CONSOLE_OUTPUT
neutralize_methods(:__debug)  unless CONSOLE_DEBUGGING

# =============================================================================
# Debugging - file load/require
# =============================================================================

if TRACE_LOADING

  __output { "TRACE_LOADING = #{TRACE_LOADING.inspect}" }

  # Indentation for #__loading_level.
  @load_level = 0

  # For checking that each module is entered and exited exactly once.
  @load_table = {}

  # Loading level and indentation.
  #
  # @param [Integer, nil] level       Default: `@load_level`.
  #
  # @return [String]
  #
  def __loading_level(level = @load_level)
    result = +''
    result << ' ' if level < 10
    result << level.to_s
    result << (' ' * ((2 * level) + 1))
  end

  # Display console output to indicate that a file is being loaded.
  #
  # @param [String] file              Actual parameter should be __FILE__.
  #
  # @return [void]
  #
  # == Usage Notes
  # Place as the first non-comment line of a Ruby source file.
  #
  def __loading(file)
    __output { "====== #{__loading_level}#{file}" }
  end

  # Display console output to indicate that a file is being loaded.
  #
  # @param [String] file              Actual parameter should be __FILE__.
  #
  # @return [void]
  #
  # == Usage Notes
  # Place as the first non-comment line of a Ruby source file.
  #
  def __loading_begin(file)
    level, still_open = @load_table[file]
    warning = [nil]
    warning << "REPEATED - last at level #{level}" if level
    warning << 'UNCLOSED' if still_open
    warning = warning.join(' <<<<<<<<<< ')
    @load_level += 1
    @load_table[file] = [@load_level, true]
    __output { "====-> #{__loading_level}#{file}#{warning}" }
  end

  # Display console output to indicate the end of a file that is being loaded.
  #
  # @param [String] file              Actual parameter should be __FILE__.
  #
  # @return [void]
  #
  # == Usage Notes
  # Place as the last non-comment line of a Ruby source file.
  #
  def __loading_end(file)
    expected, still_open = @load_table[file]
    unbalanced = (@load_level != expected)
    warning = [nil]
    warning << "UNBALANCED - expected level #{expected}" if unbalanced
    warning << 'ALREADY CLOSED' unless still_open
    warning = warning.join(' <<<<<<<<<< ')
    __output { "<-==== #{__loading_level}#{file}#{warning}" }
    @load_table[file] = [@load_level, !still_open]
    @load_level -= 1
    @load_table.clear if @load_level.zero?
  end

else

  neutralize_methods(:__loading, :__loading_begin, :__loading_end)

end

# =============================================================================
# Debugging - Concerns
# =============================================================================

if TRACE_CONCERNS

  __output { "TRACE_CONCERNS = #{TRACE_CONCERNS.inspect}" }

  # Indicate invocation of a Concern's "included" block.
  #
  # @param [Module] base
  # @param [String] concern
  #
  # @return [void]
  #
  def __included(base, concern)
    __output { "... including #{concern} in #{base}" }
  end

else

  neutralize_methods(:__included)

end

# =============================================================================
# Debugging - Rails notifications
# =============================================================================

if TRACE_NOTIFICATIONS

  # Notification specifications can be a single String, Regexp, or Array of
  # either.
  #
  # @example /.*/
  #   All notifications.
  #
  # @example /^cache_.*/
  #   Only caching notifications.
  #
  # @example [/\.action_dispatch/, /^.*process.*\.action_controller$/]
  #   Notifications related to route processing.
  #
  # @example Others
  #
  # 'load_config_initializer.railties'
  #
  # 'request.action_dispatch'
  #
  # '!connection.active_record'
  # 'sql.active_record'
  # 'instantiation.active_record'
  #
  # 'start_processing.action_controller'
  # 'process_action.action_controller'
  # 'redirect_to.action_controller'
  # 'halted_callback.action_controller'
  #
  # '!compile_template.action_view'
  # '!render_template.action_view'
  # 'render_template.action_view'
  # 'render_partial.action_view'
  #
  # 'cache_read.active_support'
  # 'cache_write.active_support'
  #
  # @see http://guides.rubyonrails.org/active_support_instrumentation.html
  #
  NOTIFICATIONS =
    case TRACE_NOTIFICATIONS
      when String then Regexp.new(TRACE_NOTIFICATIONS)
      when Regexp then TRACE_NOTIFICATIONS
      else             /.*/
    end

  __output { "TRACE_NOTIFICATIONS = #{NOTIFICATIONS.inspect}" }

  # Limit each notification display to this number of characters.
  MAX_NOTIFICATION_SIZE = 1024

  # Table for mapping notifier instance identifiers down to simple numbers.
  @notifiers = {}

  ActiveSupport::Notifications.subscribe(*NOTIFICATIONS) do |*args|
    evt = ActiveSupport::Notifications::Event.new(*args)
    tid = @notifiers[evt.transaction_id] ||= @notifiers.size + 1
    args.shift(4)
    args.map! { |arg| arg.inspect.truncate(MAX_NOTIFICATION_SIZE) }
    line = "@@@ NOTIFIER [#{tid}] %-35s (%.2f ms)" % [evt.name, evt.duration]
    __output { line << ' ' << args.join(', ') }
  end

end
