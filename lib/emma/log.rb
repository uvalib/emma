# lib/emma/log.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

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

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # The current logger.
  #
  # @return [Logger]
  #
  def self.logger
    @logger ||= Rails.logger
  end

  # Set the current logger.
  #
  # @param [Logger] logger
  #
  # @return [Logger]
  #
  def self.logger=(logger)
    @logger = logger
  end

  # Add a log message.
  #
  # If the first element of *args* is a Symbol, that is taken to be the calling
  # method.  If the next element of *args* is an Exception, a message is
  # constructed from its contents.
  #
  # @param [Integer, Symbol, nil]           severity
  # @param [Array<String,Symbol,Exception>] args
  #
  # @return [nil]
  #
  # @yield To supply additional parts to the log entry.
  # @yieldreturn [String, Array<String>]
  #
  # == Usage Notes
  # This method always returns *nil* so that it can be used by itself as the
  # final statement of a rescue block.
  #
  def self.add(severity = nil, *args)
    if severity.is_a?(String)
      args.unshift(severity)
      severity = nil
    end
    severity = log_level(severity)
    if severity >= logger.level
      args += Array.wrap(yield) if block_given?
      args.compact!
      message = []
      message << args.shift if args.first.is_a?(Symbol)
      if args.first.is_a?(Exception)
        e = args.shift
        if [YAML::SyntaxError].include?(e)
          note = (" - #{args.shift}" if args.present?)
          args.prepend("#{e.class}: #{e.message}#{note}")
        else
          args.append("#{e.message} [#{e.class}]")
        end
      end
      message += args if args.present?
      logger.add(severity, message.join(': '))
    end
    nil
  end

  # Add a DEBUG-level log message.
  #
  # @param [Array<String,Symbol,Exception>] args    Passed to #add.
  # @param [Proc]                           block   Passed to #add.
  #
  # @return [nil]
  #
  def self.debug(*args, &block)
    add(DEBUG, *args, &block)
  end

  # Add an INFO-level log message.
  #
  # @param [Array<String,Symbol,Exception>] args    Passed to #add.
  # @param [Proc]                           block   Passed to #add.
  #
  # @return [nil]
  #
  def self.info(*args, &block)
    add(INFO, *args, &block)
  end

  # Add a WARN-level log message.
  #
  # @param [Array<String,Symbol,Exception>] args    Passed to #add.
  # @param [Proc]                           block   Passed to #add.
  #
  # @return [nil]
  #
  def self.warn(*args, &block)
    add(WARN, *args, &block)
  end

  # Add an ERROR-level log message.
  #
  # @param [Array<String,Symbol,Exception>] args    Passed to #add.
  # @param [Proc]                           block   Passed to #add.
  #
  # @return [nil]
  #
  def self.error(*args, &block)
    add(ERROR, *args, &block)
  end

  # Add a FATAL-level log message.
  #
  # @param [Array<String,Symbol,Exception>] args    Passed to #add.
  # @param [Proc]                           block   Passed to #add.
  #
  # @return [nil]
  #
  def self.fatal(*args, &block)
    add(FATAL, *args, &block)
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Translate to the form expected by Logger#add.
  #
  # @param [Integer, Symbol, String] value
  # @param [Symbol, nil]             default
  #
  # @return [Integer]
  #
  def self.log_level(value, default = :unknown)
    return value if value.is_a?(Integer)
    value = value.to_s.downcase.to_sym unless value.is_a?(Symbol)
    LOG_LEVEL[value] || LOG_LEVEL[default]
  end

  # local_levels
  #
  # @return [Concurrent::Map]
  #
  # Compare with:
  # @see ActiveSupport::LoggerThreadSafeLevel#local_levels
  #
  def self.local_levels
    @local_levels ||= Concurrent::Map.new(initial_capacity: 2)
  end

  # local_log_id
  #
  # @return [Integer]
  #
  # Compare with:
  # @see ActiveSupport::LoggerThreadSafeLevel#local_log_id
  #
  def self.local_log_id
    Thread.current.__id__
  end

  # Get thread-safe log level.
  #
  # @return [Integer]
  #
  # Compare with:
  # @see ActiveSupport::LoggerThreadSafeLevel#local_level
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
  # Compare with:
  # @see ActiveSupport::LoggerThreadSafeLevel#local_level=
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
  # Compare with:
  # @see ActiveSupport::LoggerThreadSafeLevel#level
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
  # @return [Boolean]
  #
  def self.silenced
    silenced_map[local_log_id]
  end

  # Set thread-safe silenced flag.
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
      logger.local_level = ERROR
      self.silenced = true
    end
  end

  # Silences the logger for the duration of the block.
  #
  # @param [Integer, Symbol, String] tmp_level Passed to LoggerSilence#silence.
  # @param [Proc]                    block     Passed to LoggerSilence#silence.
  #
  def self.silence(tmp_level = ERROR, &block)
    if silenced?
      block.call
    else
      self.silenced = true
      tmp_level = log_level(tmp_level)
      logger.silence(tmp_level, &block).tap { self.silenced = false }
    end
  end

  # Delegate any other method to @logger.
  #
  # @param [Symbol] method
  # @param [Array]  args
  # @param [Proc]   block
  #
  def self.method_missing(method, *args, &block)
    logger.send(method, *args, &block)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The current logger.
  #
  # @return [Logger]
  #
  def logger
    Log.logger
  end

  # Set the current logger.
  #
  # @param [Logger] logger
  #
  # @return [Logger]
  #
  def logger=(logger)
    Log.logger = logger
  end

  # Create a new instance of the assigned Logger class.
  #
  # @param [Array] args               @see Logger#initialize
  #
  def self.new(*args)
    logger.class.new(*args)
  end

end

# Defined as an "alias" for Emma::Log without needing to "include Emma".
#
#--
# noinspection RubyConstantNamingConvention
#++
Log = Emma::Log

__loading_end(__FILE__)
