# lib/emma/log.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma

  # Emma::Log
  #
  module Log

    LOG_LEVEL = {
      debug:   Logger::DEBUG,
      info:    Logger::INFO,
      warn:    Logger::WARN,
      error:   Logger::ERROR,
      fatal:   Logger::FATAL,
      unknown: Logger::UNKNOWN,
    }.freeze

    # =========================================================================
    # :section: Module methods
    # =========================================================================

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

    # Indicate whether control is within a block where logging is silenced.
    #
    def self.silenced?
      @silenced ||= false
    end

    # Control whether the logger is silent.
    #
    # TODO: Not thread-safe.
    #
    # @param [Boolean,nil] go_silent
    #
    # @return [Boolean]
    # @return [nil]
    #
    def self.silent(go_silent = true)
      if go_silent && !silenced?
        @saved_log_level   = logger.local_level
        logger.local_level = Logger::ERROR
        @silenced = true
      elsif !go_silent
        logger.local_level = silenced? && @saved_log_level || logger.level
        @silenced = false
      end
    end

    # Silences the logger for the duration of the block.
    #
    # @param [Numeric, nil] temporary_level
    #
    # @see LoggerSilence#silence
    #
    def self.silence(temporary_level = Logger::ERROR, &block)
      if silenced?
        block.call
      else
        @silenced = true
        logger.silence(temporary_level, &block).tap { @silenced = false }
      end
    end

    # Add a log message.
    #
    # If the first element of *args* is a Symbol, that is taken to be the
    # calling method.  If the next element of *args* is an Exception, a message
    # is constructed from its contents.
    #
    # @param [Numeric, Symbol, nil]             severity
    # @param [Array<Symbol, Exception, String>] args
    #
    # @return [nil]
    #
    # == Usage Notes
    # This method always returns *nil* so that it can be used by itself as the
    # final statement of a rescue block.
    #
    def self.add(severity = nil, *args)
      if severity.is_a?(String)
        args.unshift(severity)
        severity = nil
      elsif !severity.is_a?(Numeric)
        severity &&= LOG_LEVEL[severity.to_s.downcase.to_sym]
      end
      severity ||= LOG_LEVEL[:unknown]
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
    # @param [Array<Symbol, Exception, String>] args
    #
    # @return [nil]
    #
    def self.debug(*args, &block)
      add(Logger::DEBUG, *args, &block)
    end

    # Add an INFO-level log message.
    #
    # @param [Array<Symbol, Exception, String>] args
    #
    # @return [nil]
    #
    def self.info(*args, &block)
      add(Logger::INFO, *args, &block)
    end

    # Add a WARN-level log message.
    #
    # @param [Array<Symbol, Exception, String>] args
    #
    # @return [nil]
    #
    def self.warn(*args, &block)
      add(Logger::WARN, *args, &block)
    end

    # Add an ERROR-level log message.
    #
    # @param [Array<Symbol, Exception, String>] args
    #
    # @return [nil]
    #
    def self.error(*args, &block)
      add(Logger::ERROR, *args, &block)
    end

    # Add a FATAL-level log message.
    #
    # @param [Array<Symbol, Exception, String>] args
    #
    # @return [nil]
    #
    def self.fatal(*args, &block)
      add(Logger::FATAL, *args, &block)
    end

    # Delegate any other method to @logger.
    #
    # @param [Symbol] method
    # @param [Array]  args
    #
    def self.method_missing(method, *args, &block)
      logger.send(method, *args, &block)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def logger
      Log.logger
    end

    def logger=(logger)
      Log.logger = logger
    end

  end

end

# Defined as an "alias" for Emma::Log without needing to "include Emma".
Log = Emma::Log

__loading_end(__FILE__)
