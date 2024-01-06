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
  # @return [Emma::Logger]
  #
  def self.logger
    # noinspection RbsMissingTypeSignature
    @logger ||= new(progname: 'EMMA')
  end

  # Add a log message.
  #
  # If the first element of *args* is a Symbol, that is taken to be the calling
  # method.  If the next element of *args* is an Exception, a message is
  # constructed from its contents.
  #
  # @param [Integer, Symbol, nil]             severity
  # @param [Array<String,Symbol,Exception,*>] args
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
    return if Logger.suppressed?
    return if (level = level_for(severity)) < logger.level
    args.concat(Array.wrap(yield)) if block_given?
    args.compact!
    parts = []
    parts << args.shift if args.first.is_a?(Symbol)
    error = (args.shift if args.first.is_a?(Exception))
    if error.is_a?(YAML::SyntaxError)
      note = (" - #{args.shift}" if args.present?)
      parts << "#{error.class}: #{error.message}#{note}"
    elsif error
      note = (error.messages[1..].presence if error.respond_to?(:messages))
      note &&= ' - %s' % note.join('; ')
      args << "#{error.message} [#{error.class}]#{note}"
    end
    message = parts.concat(args).join(': ')
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
  def self.level_for(value, default = :unknown)
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
    level = level_for(value, default)
    LEVEL_NAME[level]
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
  class << self
    delegate :suppressed?, :suppress, :suppress=, to: ::Logger
  end

  # Set logger suppression in general or for the duration of a block.
  #
  # @param [Boolean, nil] suppress
  #
  # @yield If given, the indicated state is only for the duration of the block.
  #
  def self.silence(suppress = nil)
    if block_given?
      # If a block is given then it is assumed that the intended state is to
      # suppress logging for the duration of the block.
      suppress = suppress.nil? || !!suppress
      current  = Logger.suppressed?
      if suppress == current
        # If the requested state is already in effect nothing extra is needed.
        yield
      else
        # Otherwise, toggle the state for the duration of the block.
        begin
          Logger.suppressed = !current
          yield
        ensure
          Logger.suppressed = current
        end
      end
    else
      # If no block is given then this can only be a directive to set the
      # global silence state.  For safety, an explicit argument is required.
      raise 'no argument or block given' unless suppress.is_a?(BoolType)
      Logger.suppressed = suppress
    end
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Create a new Emma::Log instance based on *src* if provided.
  #
  # @param [::Logger, String, IO, nil] src
  # @param [Array]                     args
  # @param [Hash]                      opt        @see Logger#initialize
  #
  # @option opt [String] :progname    If not given, one will be generated.
  #
  # @return [Emma::Logger]
  #
  def self.new(src = nil, *args, **opt)
    opt[:progname] ||= anonymous_progname
    logger = Emma::Logger.new(src, *args, **opt)
    ActiveSupport::TaggedLogging.new(logger).tap do |log|
      tags = src&.try(:formatter)&.try(:current_tags)
      log.formatter.push_tags(tags) if tags.present?
    end
  end

  # Generate a new distinct :progname for an anonymous instance.
  #
  # @param [String]  base_name
  # @param [Boolean] increment
  #
  # @return [String]
  #
  #--
  # noinspection RbsMissingTypeSignature
  #++
  def self.anonymous_progname(base_name: 'EMM%d', increment: true)
    @anonymous_count ||= 0
    @anonymous_count += 1 if increment
    base_name % @anonymous_count
  end

  # Replace the configured logger.
  #
  # @param [Any]    config
  # @param [String] progname
  # @param [Hash]   opt
  #
  # @return [nil]                             If *config* is invalid.
  # @return [Emma::Logger]                    Direct replacement.
  # @return [ActiveSupport::BroadcastLogger]  Original, possibly modified.
  #
  def self.replace(config, progname:, **opt)
    if config.respond_to?(:logger=)
      src    = config.logger
      update = ->(new_src) { config.logger = new_src }
    elsif config.is_a?(Hash)
      src    = config[:logger]
      update = ->(new_src) { config[:logger] = new_src }
    else
      return warn {"#{self}.#{__method__}: invalid config: #{config.inspect}"}
    end
    opt.reverse_merge!(progname: progname)
    loggers = (src.broadcasts if src.is_a?(ActiveSupport::BroadcastLogger))

    # noinspection RubyMismatchedReturnType
    if loggers&.any? { |log| log.progname == progname }
      # The provided logger already broadcasts to `progname`, so update it.
      # This branch does not invoke `update.(src)` since the provided
      # BroadcastLogger is just updated in-place.
      loggers.map! do |logger|
        if logger.progname.blank? || (logger.progname == progname)
          new(logger, **opt)
        else
          new(logger, **opt.except(:progname))
        end
      end
      src

    elsif loggers
      # The provided logger may have just been assigned as a default without
      # regard to distinguishing loggers by progname, so create a new one.
      loggers = loggers.presence&.dup || [nil]
      loggers.map! do |logger|
        new(logger, **opt)
      end
      update.(ActiveSupport::BroadcastLogger.new(*loggers))

    elsif src.nil? || src.is_a?(::Logger)
      # noinspection RubyMismatchedArgumentType
      update.(new(src, **opt))

    else
      warn { "#{self}.#{__method__}: unexpected src: #{src.inspect}" }
    end
  end
    .tap { |meth| neutralize(meth) if LOG_SILENCER }

end

# Defined as an "alias" for Emma::Log without needing to "include Emma".
#
#--
# noinspection RubyConstantNamingConvention
#++
Log = Emma::Log

__loading_end(__FILE__)
