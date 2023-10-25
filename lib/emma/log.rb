# lib/emma/log.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'logger'

# Emma::Log
#
module Emma::Log

  include Logger::Severity

  LOG_LEVEL = {
    debug:   DEBUG,
    info:    INFO,
    warn:    WARN,
    error:   ERROR,
    fatal:   FATAL,
    unknown: UNKNOWN,
  }.freeze

  LEVEL_NAME =
    LOG_LEVEL.invert.transform_values { |v| v.to_s.upcase }.freeze

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # The current application logger.
  #
  # @return [Logger]
  #
  def self.logger
    # noinspection RbsMissingTypeSignature
    @logger ||=
      if LOG_TO_STDOUT
        new(STDOUT, progname: 'EMMA')
      else
        new(Rails.application.config.default_log_file, progname: 'EMMA')
      end
  end

  # Add a log message.
  #
  # If the first element of *args* is a Symbol, that is taken to be the calling
  # method.  If the next element of *args* is an Exception, a message is
  # constructed from its contents.
  #
  # @param [Integer, Symbol, nil]               severity
  # @param [Array<String,Symbol,Exception,Any>] args
  #
  # @return [nil]
  #
  # @yield To supply additional parts to the log entry.
  # @yieldreturn [String, Array<String>]
  #
  # === Usage Notes
  # This method always returns *nil* so that it can be used by itself as the
  # final statement of a rescue block.
  #
  # If not logging to STDOUT then the message is echoed on $stderr so that it
  # is also visible on console output without having to switch to log output.
  #
  def self.add(severity, *args)
    return if (level = log_level(severity)) < logger.level
    args += Array.wrap(yield) if block_given?
    args.compact!
    parts = []
    parts << args.shift if args.first.is_a?(Symbol)
    error = (args.shift if args.first.is_a?(Exception))
    if error.is_a?(YAML::SyntaxError)
      note = (" - #{args.shift}" if args.present?)
      args.prepend("#{error.class}: #{error.message}#{note}")
    elsif error
      note = (error.messages[1..].presence if error.respond_to?(:messages))
      note &&= ' - %s' % note.join('; ')
      args << "#{error.message} [#{error.class}]#{note}"
    end
    message = [*parts, *args].join(': ')
    logger.add(level, message)
    __output(message) unless LOG_TO_STDOUT
  end

  # Add a DEBUG-level log message.
  #
  # @param [Array<String,Symbol,Exception,*>] args  Passed to #add.
  # @param [Proc]                             blk   Passed to #add.
  #
  # @return [nil]
  #
  def self.debug(*args, &blk)
    add(DEBUG, *args, &blk)
  end

  # Add an INFO-level log message.
  #
  # @param [Array<String,Symbol,Exception,*>] args  Passed to #add.
  # @param [Proc]                             blk   Passed to #add.
  #
  # @return [nil]
  #
  def self.info(*args, &blk)
    add(INFO, *args, &blk)
  end

  # Add a WARN-level log message.
  #
  # @param [Array<String,Symbol,Exception,*>] args  Passed to #add.
  # @param [Proc]                             blk   Passed to #add.
  #
  # @return [nil]
  #
  def self.warn(*args, &blk)
    add(WARN, *args, &blk)
  end

  # Add an ERROR-level log message.
  #
  # @param [Array<String,Symbol,Exception,*>] args  Passed to #add.
  # @param [Proc]                             blk   Passed to #add.
  #
  # @return [nil]
  #
  def self.error(*args, &blk)
    add(ERROR, *args, &blk)
  end

  # Add a FATAL-level log message.
  #
  # @param [Array<String,Symbol,Exception,*>] args  Passed to #add.
  # @param [Proc]                             blk   Passed to #add.
  #
  # @return [nil]
  #
  def self.fatal(*args, &blk)
    add(FATAL, *args, &blk)
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Translate to the form expected by Logger#add.
  #
  # @param [Integer, Symbol, String, nil] value
  # @param [Symbol]                       default
  #
  # @return [Integer]
  #
  def self.log_level(value, default = :unknown)
    # noinspection RubyMismatchedReturnType
    return value if value.is_a?(Integer)
    value = value.to_s.downcase.to_sym unless value.is_a?(Symbol)
    LOG_LEVEL[value] || LOG_LEVEL[default]
  end

  # Return the display name for a log level.
  #
  # @param [Integer, Symbol, String, nil] value
  # @param [Symbol]                       default
  #
  # @return [String]
  #
  def self.level_name(value, default = :unknown)
    level = log_level(value, default)
    LEVEL_NAME[level]
  end

  # local_levels
  #
  # @return [Concurrent::Map]
  #
  # === Implementation Notes
  # Compare with ActiveSupport::LoggerThreadSafeLevel#local_levels
  #
  def self.local_levels
    @local_levels ||= Concurrent::Map.new(initial_capacity: 2)
  end

  # local_log_id
  #
  # @return [Integer]
  #
  # === Implementation Notes
  # Compare with ActiveSupport::LoggerThreadSafeLevel#local_log_id
  #
  def self.local_log_id
    Thread.current.__id__
  end

  # Get thread-safe log level.
  #
  # @return [Integer]
  #
  # === Implementation Notes
  # Compare with ActiveSupport::LoggerThreadSafeLevel#local_level
  #
  def self.local_level
    local_levels[local_log_id]
  end

  # Set thread-safe log level.
  #
  # @param [Integer, Symbol, String, nil] value
  #
  # @return [Integer]
  # @return [nil]                   If *value* is *nil*.
  #
  # === Implementation Notes
  # Compare with ActiveSupport::LoggerThreadSafeLevel#local_level=
  #
  def self.local_level=(value)
    if value
      local_levels[local_log_id] = log_level(value)
    else
      local_levels.delete(local_log_id) and nil
    end
  end

  # Thread-safe log level.
  #
  # @return [Integer]
  #
  # === Implementation Notes
  # Compare with ActiveSupport::LoggerThreadSafeLevel#level
  #
  def self.level
    local_level || logger.level
  end

  # Thread-safe storage for silenced status.
  #
  # @return [Concurrent::Map]
  #
  def self.silenced_map
    @silenced_map ||= Concurrent::Map.new(initial_capacity: 2)
  end

  # Indicate whether control is within a block where logging is silenced.
  #
  def self.silenced?
    silenced.present?
  end

  # Get thread-safe silenced flag.
  #
  # @return [Boolean, nil]
  #
  def self.silenced
    silenced_map[local_log_id]
  end

  # Set thread-safe silenced flag.
  #
  # @param [Boolean] flag
  #
  # @return [Boolean]
  #
  def self.silenced=(flag)
    silenced_map[local_log_id] = flag
  end

  # Thread-safe storage for silenced status.
  #
  # @return [Concurrent::Map]
  #
  def self.saved_log_level
    @saved_log_level ||= Concurrent::Map.new(initial_capacity: 2)
  end

  # Control whether the logger is silent.
  #
  # @param [Boolean,nil] go_silent
  #
  # @return [Boolean]
  # @return [nil]
  #
  def self.silent(go_silent = true)
    if !go_silent
      logger.local_level = saved_log_level.delete(local_log_id) || level
      self.silenced = false
    elsif !silenced?
      saved_log_level[local_log_id] = logger.local_level
      logger.local_level = FATAL
      self.silenced = true
    end
  end

  # Silences the logger for the duration of the block.
  #
  # @param [Integer, Symbol, String] tmp_level Passed to LoggerSilence#silence.
  # @param [Proc]                    block     Passed to LoggerSilence#silence.
  #
  def self.silence(tmp_level = FATAL, &block)
    if silenced?
      block.call
    else
      begin
        self.silenced = true
        logger.silence(log_level(tmp_level), &block)
      ensure
        self.silenced = false
      end
    end
  end

  # Delegate any other method to @logger.
  #
  # @param [Symbol]   meth
  # @param [Array<*>] args
  # @param [Proc]     blk
  #
  def self.method_missing(meth, *args, &blk)
    logger.send(meth, *args, &blk)
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Create a new instance of the assigned Logger class.
  #
  # @param [::Logger, String, IO, nil] src
  # @param [Hash]                      opt        @see Logger#initialize
  #
  # @option opt [Integer]             :level      Logging level (def.: #DEBUG)
  # @option opt [String]              :progname   Default: nil.
  # @option opt [::Logger::Formatter] :formatter  Default: from Log.logger
  #
  # @return [::Logger]
  #
  def self.new(src = nil, **opt)
    ignored = opt.except(:progname, :level, :formatter, :datetime_format)
    __output "Log.new ignoring options #{ignored.keys}" if ignored.present?
    log = src || logger
    log = log.clone                             if log.is_a?(::Logger)
    log = Emma::Logger.new(log, **opt)          unless log.is_a?(::Logger)
    log.progname        = opt[:progname]
    log.level           = opt[:level]           if opt[:level]
    log.datetime_format = opt[:datetime_format] if opt[:datetime_format]
    log.formatter       = opt[:formatter]       if opt[:formatter]
    log.formatter       = log.formatter&.clone  unless opt[:formatter]
    # noinspection RubyMismatchedReturnType
    log
  end

end

# Defined as an "alias" for Emma::Log without needing to "include Emma".
#
#--
# noinspection RubyConstantNamingConvention
#++
Log = Emma::Log

__loading_end(__FILE__)
