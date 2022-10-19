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

# Convert a string to UTF-8 encoding.
#
# @param [String, Any] v
#
# @return [String, Any]
#
def to_utf8(v)
  return v unless v.is_a?(String)
  return v if (enc = v.encoding) == (utf = Encoding::UTF_8)
  Encoding::Converter.new(enc, utf).convert(v) rescue v.dup.force_encoding(utf)
end

# =============================================================================
# Debugging - console output
# =============================================================================

public

# For AWS, add indentation prefix characters to help make debugging output
# stand out from normal Rails.logger entries.
#
# @type [String]
#
CONS_INDENT = $stderr.isatty ? '' : '_   '

# Write indented line(s) to $stderr.
#
# @param [Array<*>] args
# @param [Hash]     opt
#
# @option opt [String]                   :leader     At the start of each line.
# @option opt [String, Integer]          :indent     Default: #CONS_INDENT.
# @option opt [String]                   :separator  Default: "\n"
# @option opt [Boolean]                  :debug      Structure for debug output
# @option opt [Symbol, Integer, Boolean] :log        Note [1]
#
# @return [nil]
#
# @yield To supply additional items to output.
# @yieldreturn [Array<String>]
#
# == Usage Notes
# [1] When deployed, this option will create a log entry rather than produce
# $stderr output.  If not deployed, the log entry is created in addition to
# $stderr output.
#
def __output_impl(*args, **opt)
  return if defined?(Log) && Log.silenced?
  sep = opt[:separator] || "\n"

  # Construct the string that is prepended to each output line.
  indent = opt[:indent] || (sep.include?("\n") ? CONS_INDENT : '')
  indent = (' ' * indent if indent.is_a?(Integer) && indent.positive?)
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
        arg = to_utf8(arg)
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

# Write indented line(s) to $stderr if CONSOLE_OUTPUT is *true*.
#
# @param [Array<*>] args              Passed to #__output_impl.
# @param [Hash]     opt               Passed to #__output_impl.
# @param [Proc]     block             Passed to #__output_impl.
#
# == Usage Notes
# The method is only functional if #CONSOLE_OUTPUT is true.
#
def __output(*args, **opt, &block)
  __output_impl(*args, **opt, &block)
end

neutralize(:__output) unless CONSOLE_OUTPUT

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
# @param [Array<*>] args              Passed to #__output_impl.
# @param [Hash]     opt               Passed to #__output_impl.
# @param [Proc]     block             Passed to #__output_impl.
#
# @return [nil]
#
def __debug_impl(*args, **opt, &block)
  opt.reverse_merge!(
    debug:    true,
    leader:   DEBUG_LEADER,
    max:      DEBUG_MAX,
    omission: '...'
  )
  __output_impl(*args, **opt, &block)
end

# Write indented debug line(s) to $stderr if CONSOLE_DEBUGGING is *true*.
#
# @param [Array<*>] args              Passed to #__debug_impl.
# @param [Hash]     opt               Passed to #__debug_impl.
# @param [Proc]     block             Passed to #__debug_impl.
#
def __debug(*args, **opt, &block)
  __debug_impl(*args, **opt, &block)
end

neutralize(:__debug) unless CONSOLE_DEBUGGING

# =============================================================================
# Debugging - file load/require
# =============================================================================

__output_impl { "TRACE_LOADING = #{TRACE_LOADING.inspect}" } if TRACE_LOADING

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
# == Usage Notes
# Place as the first non-comment line of a Ruby source file.
#
def __loading(file)
  __output_impl { "====== #{__loading_level}#{file}" }
end

# Display console output to indicate that a file is being loaded.
#
# @param [String] file                Actual parameter should be __FILE__.
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
  __output_impl { "====-> #{__loading_level}#{file}#{warning}" }
end

# Display console output to indicate the end of a file that is being loaded.
#
# @param [String] file                Actual parameter should be __FILE__.
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
  __output_impl { "<-==== #{__loading_level}#{file}#{warning}" }
  @load_table[file] = [@load_level, !still_open]
  @load_level -= 1
  @load_table.clear if @load_level.zero?
  nil
end

neutralize(:__loading, :__loading_begin, :__loading_end) unless TRACE_LOADING

# =============================================================================
# Debugging - Concerns
# =============================================================================

__output_impl("TRACE_CONCERNS = #{TRACE_CONCERNS.inspect}") if TRACE_CONCERNS

# Indicate invocation of a module's "included" block.
#
# @param [Module]      base
# @param [Module]      mod
# @param [String, nil] tag
#
# @return [nil]
#
def __included(base, mod, tag = nil)
  __output_impl { "... including #{tag || mod.try(:name) || mod} in #{base}" }
end

neutralize(:__included) unless TRACE_CONCERNS

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

  __output_impl { "TRACE_NOTIFICATIONS = #{NOTIFICATIONS.inspect}" }

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
    __output_impl { line << ' ' << args.join(', ') }
  end

end
