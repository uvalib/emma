# lib/_trace.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Loader debugging.

# =============================================================================
# Debugging - environment variables
# =============================================================================

public

# Access environment variable and return the expected type.
#
# @param [String]       var       Name of environment variable.
# @param [Object, nil]  default   Default value if `ENV[*var*]` is not present.
#                                 or if it's value is blank. (This is not
#                                 interpreted so it should be a value of the
#                                 appropriate type.)
#
# @return [Boolean]               For boolean-like strings.
# @return [Regexp]                For Regexp-like strings.
# @return [String]                For everything else except:
# @return [Object]                Non-string environment variable value.
# @return [nil]                   If missing and *default* is *nil*.
#
def env(var, default = nil)
  case (value = ENV[var].to_s.strip.presence)
    when nil                  then default
    when /^true$/i            then true
    when /^false$/i           then false
    when %r{^/(.*)/(i?)$}     then Regexp.new($1, $2.presence)
    when /^%r(.)(.*)\1(i?)$/  then Regexp.new($2, $3.presence)
    else                           value
  end
end

# =============================================================================
# Constants
# =============================================================================

public

# Control console debugging output.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
CONSOLE_DEBUGGING = env('CONSOLE_DEBUGGING', false)

# Control tracking of file load order.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #__loading
#
TRACE_LOADING = env('TRACE_LOADING', false)

# Control tracking of invocation of Concern "included" blocks.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #__included
#
TRACE_CONCERNS = env('TRACE_CONCERNS', false)

# Control tracking of Rails notifications.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #NOTIFICATIONS
#
TRACE_NOTIFICATIONS = env('TRACE_NOTIFICATIONS', false)

# =============================================================================
# Debugging - console output
# =============================================================================

require 'io/console'

# For AWS, add indentation prefix characters to help make debugging output
# stand out from normal Rails.logger entries.
CONS_INDENT = $stderr.isatty ? '' : '_   '

# Write indented line(s) to $stderr.
#
# @param [Array<Hash,Array,String,*>] args
#
# @option args.last [String]          :leader     At the start of each line.
# @option args.last [String, Integer] :indent     Default: #CONS_INDENT.
# @option args.last [String]          :separator  Default: "\n"
#
# @yield Supply additional items to output.
# @yieldreturn [Array<String>]
#
# @return [nil]
#
def __output(*args)
  return if defined?(Log) && Log.silenced?
  opt    = args.extract_options!
  sep    = opt[:separator] || "\n"
  indent = opt[:indent]    || (sep.include?("\n") ? CONS_INDENT : '')
  indent = (' ' * indent if indent.is_a?(Integer) && (indent > 0))
  leader = "#{indent}#{opt[:leader]}"
  leader += ' ' unless (leader == indent.to_s) || leader.end_with?(' ')
  args += Array.wrap(yield) if block_given?
  lines = args.join(sep).gsub(/\n/, "\n#{leader}").strip
  $stderr.puts(leader + lines)
  $stderr.flush
  nil
end

# Debugging statements are neutralized unless #CONSOLE_DEBUGGING is *true*.
def __debug(*); end unless CONSOLE_DEBUGGING

# Write indented debug line(s) to $stderr.
#
# @param [Array<Hash,Array,String,*>] args
#
# args[-1] [Hash]                     Options passed to #__output.
#
# @yield Supply additional items to output.
# @yieldreturn [Hash,Array,String,*]
#
# @return [nil]
#
# @see #__output
#
def __debug(*args)
  opt = args.extract_options!
  args += Array.wrap(yield) if block_given?
  __output(opt) do
    args.flat_map do |arg|
      case arg
        when Hash   then arg.map { |k, v| "#{k} = #{v}" }
        when Array  then arg
        when String then arg
        else             arg.inspect
      end
    end
  end
end if CONSOLE_DEBUGGING

# =============================================================================
# Debugging - file load/require
# =============================================================================

if TRACE_LOADING

  __output "TRACE_LOADING = #{TRACE_LOADING.inspect}"

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
    __output "====== #{__loading_level}#{file}"
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
    __output "====-> #{__loading_level}#{file}#{warning}"
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
    __output "<-==== #{__loading_level}#{file}#{warning}"
    @load_table[file] = [@load_level, !still_open]
    @load_level -= 1
    @load_table.clear if @load_level.zero?
  end

else

  def __loading(*)
  end

  def __loading_begin(*)
  end

  def __loading_end(*)
  end

end

# =============================================================================
# Debugging - Concerns
# =============================================================================

if TRACE_CONCERNS

  __output "TRACE_CONCERNS = #{TRACE_CONCERNS.inspect}"

  # Indicate invocation of a Concern's "included" block.
  #
  # @param [Module] base
  # @param [String] concern
  #
  # @return [void]
  #
  def __included(base, concern)
    __output "... including #{concern} in #{base}"
  end

else

  def __included(*)
  end

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

  __output "TRACE_NOTIFICATIONS = #{NOTIFICATIONS.inspect}"

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
    line << ' ' << args.join(', ')
    __output line
  end

end
