# lib/_trace.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Console output and loader debugging.

require 'io/console'

# =============================================================================
# Debugging - metaprogramming
# =============================================================================

public

# Used to neutralize method(s) if they are not supposed to be enabled.
#
# @param [Array<Symbol>] methods
#
# @return [void]
#
def neutralize(*methods)
  methods.each do |meth|
    define_method(meth) { |*, **| }
  end
end

# Used to neutralize method(s) and raise an exception if they are called.
#
# @param [Array<Symbol>] methods
#
# @return [void]
#
def disallow(*methods)
  methods.each do |meth|
    define_method(meth) do |*, **|
      raise "#{meth} not expected to be called" if not_deployed?
    end
  end
end

# Convert a string to UTF-8 encoding.
#
# @param [any, nil] v                 String
#
# @return [String, any, nil]
#
def to_utf8(v)
  return v unless v.is_a?(String)
  return v if (enc = v.encoding) == (utf = Encoding::UTF_8)
  # noinspection RubyMismatchedArgumentType
  Encoding::Converter.new(enc, utf).convert(v) rescue v.dup.force_encoding(utf)
end

# =============================================================================
# Debugging - console output
# =============================================================================

public

# If *true*, log output is going to $stdout rather than a file.
#
# @type [Boolean]
#
LOG_TO_STDOUT = true?(ENV['RAILS_LOG_TO_STDOUT'])

# For AWS, add line prefix characters to help make debugging output stand out
# from normal log entries.
#
# @type [String]
#
OUTPUT_PREFIX = LOG_TO_STDOUT ? '| ' : ''

# Write indented line(s) to $stderr.
#
# @param [Array<*>] args
# @param [Hash]     opt
#
# @option opt [String]                   :leader     At the start of each line.
# @option opt [String, Integer]          :indent     Default: none.
# @option opt [String]                   :separator  Default: "\n"
# @option opt [Boolean]                  :debug      Structure for debug output
# @option opt [Symbol, Integer, Boolean] :log        Note [1]
# @option opt [Boolean]                  :no_log     Note [2]
#
# @return [nil]
#
# @yield To supply additional items to output.
# @yieldreturn [Array<String>]
#
# === Usage Notes
# - [1] When deployed, this option will create a log entry rather than produce
#       $stderr output.  If not deployed, the log entry is created in addition
#       to $stderr output.
# - [2] During initial trace output (if enabled) it makes sense to only send to
#       $stderr so that the overall trace output doesn't switch forms as soon
#       as `Log.add` starts working.
#
def __output_impl(*args, **opt)
  return if Logger.try(:suppressed?)
  sep = opt[:separator] || "\n"

  # Construct the string that is prepended to each output line.
  indent = opt[:indent]
  indent = (' ' * indent if indent.positive?) if indent.is_a?(Integer)
  indent = "#{OUTPUT_PREFIX}#{indent}"
  leader = "#{indent}#{opt[:leader]}"
  leader << ' ' unless (leader == indent) || leader.match?(/\s$/)

  # Combine arguments and block results into a single string.
  args.concat(Array.wrap(yield)) if block_given?
  if opt[:debug]
    max  = positive(opt[:max].to_i - leader.size)
    omit = opt[:omission]
    args =
      args.flat_map do |arg|
        case arg
          when Hash   then arg.map { "#{_1} = #{_2}" }
          when Array  then arg.map(&:to_s)
          when String then arg
          else             arg.inspect
        end
      end
    if max && omit
      args.map! { _1.truncate_bytes(max, omission: omit) rescue nil }
    elsif max
      args.map! { _1.truncate_bytes(max) rescue nil }
    end
  end
  lines = leader + args.compact.join(sep).gsub(/\n/, "\n#{leader}").strip

  unless opt[:no_log] || !defined?(Log)
    begin

      # Apply log formatting rather than writing directly.
      return Log.debug(lines) if LOG_TO_STDOUT

      # For desktop builds, if explicitly requested, copy output to the log.
      unless (level = opt[:log]).blank? || application_deployed?
        level = Log.level_for(level, :debug)
        Log.add(level, lines)
      end

    rescue
      # Too early -- fall through to the normal write to stdout.
    end
  end

  # Emit output.
  $stdout.flush
  $stderr.flush
  $stderr.puts(lines)
  $stderr.flush
  nil
end

# Write indented line(s) to $stderr if CONSOLE_OUTPUT is *true*.
#
# @param [Array<*>] args
# @param [Hash]     opt
# @param [Proc]     blk
#
# @return [nil]
#
# === Usage Notes
# The method is only functional if #CONSOLE_OUTPUT is true.
#
def __output(*args, **opt, &blk)
  __output_impl(*args, **opt, &blk)
end
  .tap { neutralize(_1) unless CONSOLE_OUTPUT }

# =============================================================================
# Debugging - console debugging
# =============================================================================

public

# Initial characters which mark a debug line.
#
# @type [String]
#
DEBUG_LEADER = ''

# Truncate long debug output lines to this number of characters.
#
# @type [Integer]
#
DEBUG_MAX = 2048

# Write indented debug line(s) to $stderr.
#
# @param [Array<*>] args
# @param [Hash]     opt
# @param [Proc]     blk
#
# @return [nil]
#
def __debug_impl(*args, **opt, &blk)
  opt.reverse_merge!(
    debug:    true,
    leader:   DEBUG_LEADER,
    max:      DEBUG_MAX,
    omission: '...'
  )
  __output_impl(*args, **opt, &blk)
end

# Write indented debug line(s) to $stderr if CONSOLE_DEBUGGING is *true*.
#
# @param [Array<*>] args
# @param [Hash]     opt
# @param [Proc]     blk
#
# @return [nil]
#
def __debug(*args, **opt, &blk)
  __debug_impl(*args, **opt, &blk)
end
  .tap { neutralize(_1) unless CONSOLE_DEBUGGING }

# =============================================================================
# Debugging - trace output
# =============================================================================

public

# Output a trace line which always goes to $stderr.
#
# @param [Array<*>] args
# @param [Hash]     opt
# @param [Proc]     blk
#
# @return [nil]
#
def __trace_impl(*args, **opt, &blk)
  opt[:no_log] = true unless opt.key?(:no_log)
  __output_impl(*args, **opt, &blk)
end

# Output a trace line which always goes to $stderr.
#
# @param [Array<*>] args
# @param [Hash]     opt
# @param [Proc]     blk
#
# @return [nil]
#
def __trace(*args, **opt, &blk)
  __trace_impl(*args, **opt, &blk)
end

# =============================================================================
# Debugging - file load/require
# =============================================================================

__trace { "TRACE_LOADING = #{TRACE_LOADING.inspect}" } if TRACE_LOADING

# For AWS, make the indentation standout in CloudWatch.
#
# @type [String]
#
LOAD_INDENT = $stderr.isatty ? ' ' : '_'

# Indentation for #__loading_level.
@load_level = 0

# For checking that each module is entered and exited exactly once.
@load_table = {}

# Loading level and indentation.
#
# @param [Integer] level
#
# @return [String]
#
def __loading_level(level = @load_level)
  number = '%-2d' % level
  indent = LOAD_INDENT * (2 * level)
  gap    = ' '
  "#{number}#{indent}#{gap}"
end

# Display console output to indicate that a file is being loaded.
#
# @param [String] file                Actual parameter should be __FILE__.
#
# @return [void]
#
# === Usage Notes
# Place as the first non-comment line of a Ruby source file.
#
def __loading(file)
  __trace { "====== #{__loading_level}#{file}" }
end
  .tap { neutralize(_1) unless TRACE_LOADING }

# Display console output to indicate that a file is being loaded.
#
# @param [String] file                Actual parameter should be __FILE__.
#
# @return [void]
#
# === Usage Notes
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
  __trace { "====-> #{__loading_level}#{file}#{warning}" }
end
  .tap { neutralize(_1) unless TRACE_LOADING }

# Display console output to indicate the end of a file that is being loaded.
#
# @param [String] file                Actual parameter should be __FILE__.
#
# @return [void]
#
# === Usage Notes
# Place as the last non-comment line of a Ruby source file.
#
def __loading_end(file)
  expected, still_open = @load_table[file]
  unbalanced = (@load_level != expected)
  warning = [nil]
  warning << "UNBALANCED - expected level #{expected}" if unbalanced
  warning << 'ALREADY CLOSED' unless still_open
  warning = warning.join(' <<<<<<<<<< ')
  __trace { "<-==== #{__loading_level}#{file}#{warning}" }
  @load_table[file] = [@load_level, !still_open]
  @load_level -= 1
  @load_table.clear if @load_level.zero?
  nil
end
  .tap { neutralize(_1) unless TRACE_LOADING }

# =============================================================================
# Debugging - Concerns
# =============================================================================

__trace { "TRACE_CONCERNS = #{TRACE_CONCERNS.inspect}" } if TRACE_CONCERNS

# Indicate invocation of a module's "included" block.
#
# @param [Module]      base
# @param [Module]      mod
# @param [String, nil] tag
#
# @return [nil]
#
def __included(base, mod, tag = nil)
  __trace { "... including #{tag || mod.try(:name) || mod} in #{base}" }
end
  .tap { neutralize(_1) unless TRACE_CONCERNS }

# =============================================================================
# Debugging - Rails notifications
# =============================================================================

if TRACE_NOTIFICATIONS

  # Notification specifications can be a single String, Regexp, or Array of
  # either.
  #
  # @example All notifications
  #   /.*/
  #
  # @example Only caching notifications
  #   /^cache_.*/
  #
  # @example Notifications related to route processing
  #   [/\.action_dispatch/, /^.*process.*\.action_controller$/]
  #
  # @example Others
  #   * 'load_config_initializer.railties'
  #
  #   * 'request.action_dispatch'
  #
  #   * '!connection.active_record'
  #   * 'sql.active_record'
  #   * 'instantiation.active_record'
  #
  #   * 'start_processing.action_controller'
  #   * 'process_action.action_controller'
  #   * 'redirect_to.action_controller'
  #   * 'halted_callback.action_controller'
  #
  #   * '!compile_template.action_view'
  #   * '!render_template.action_view'
  #   * 'render_template.action_view'
  #   * 'render_partial.action_view'
  #
  #   * 'cache_read.active_support'
  #   * 'cache_write.active_support'
  #
  # @see http://guides.rubyonrails.org/active_support_instrumentation.html
  #
  NOTIFICATIONS =
    case TRACE_NOTIFICATIONS
      when String then Regexp.new(TRACE_NOTIFICATIONS)
      when Regexp then TRACE_NOTIFICATIONS
      else             /.*/
    end

  __trace { "TRACE_NOTIFICATIONS = #{NOTIFICATIONS.inspect}" }

  # Limit each notification display to this number of characters.
  MAX_NOTIFICATION_SIZE = 1024

  # Table for mapping notifier instance identifiers down to simple numbers.
  @notifiers = {}

  ActiveSupport::Notifications.subscribe(*NOTIFICATIONS) do |*args|
    evt = ActiveSupport::Notifications::Event.new(*args)
    tid = @notifiers[evt.transaction_id] ||= @notifiers.size + 1
    args.shift(4)
    args.map! { _1.inspect.truncate(MAX_NOTIFICATION_SIZE) }
    line = "@@@ NOTIFIER [#{tid}] %-35s (%.2f ms)" % [evt.name, evt.duration]
    __output_impl { line << ' ' << args.join(', ') }
  end

end
