# lib/emma/logger.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma

  # Application logger.
  #
  class Logger < ActiveSupport::Logger

    include Emma::Common

    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveSupport::LoggerSilence
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    FILTERING =
      ENV['EMMA_LOG_FILTERING']
        .then { |v| LOG_TO_STDOUT ? !false?(v) : true?(v) }

    AWS_FORMATTING =
      ENV['EMMA_LOG_AWS_FORMATTING']
        .then { |v| LOG_TO_STDOUT ? !false?(v) : true?(v) }

    # =========================================================================
    # :section: ActiveSupport::Logger overrides
    # =========================================================================

    public

    # Options expected by ::Logger#initialize
    #
    # @type [Array<Symbol>]
    #
    STD_LOGGER_OPT = %i[
      level
      progname
      formatter
      datetime_format
      binmode
      shift_period_suffix
    ].freeze

    # Additional options supported by Emma::Logger#initialize
    #
    # @type [Array<Symbol>]
    #
    EMMA_LOGGER_OPT = %i[default_formatter].freeze

    # Options supported by Emma::Logger#initialize
    #
    # @type [Array<Symbol>]
    #
    LOGGER_OPT = (STD_LOGGER_OPT + EMMA_LOGGER_OPT).freeze

    # Create a new instance.
    #
    # @param [::Logger, String, IO, nil] src
    # @param [Array]                     args   @see ::Logger#initialize
    # @param [Hash]                      opt    @see ::Logger#initialize
    #
    # @return [Emma::Logger]
    #
    def initialize(src = nil, *args, **opt)
      local   = opt.extract!(*EMMA_LOGGER_OPT)
      invalid = opt.slice!(*STD_LOGGER_OPT)
      if invalid.present? && Log.debug? && (stack = caller.join("\n"))
        Log.debug do
          "#{self.class}: ignoring invalid: #{invalid.inspect} at\n#{stack}"
        end
      end

      if src.is_a?(::Logger)
        opt[:progname]        ||= src.progname
        opt[:level]           ||= src.level
        opt[:formatter]       ||= src.formatter&.dup
        opt[:datetime_format] ||= src.datetime_format
        logdev = src.instance_variable_get(:@logdev)&.dev
      else
        opt[:level]           ||= Rails.configuration.log_level
        logdev = src
      end
      logdev ||= LOG_TO_STDOUT ? STDOUT : Rails.configuration.default_log_file

      super(logdev, *args, **opt)

      @default_formatter   = local[:default_formatter]
      @default_formatter ||= Emma::Logger::Formatter.new
      @formatter = @default_formatter unless opt[:formatter]
    end

    # Prefix all lines with the same leading log information, and reduce log
    # entries if #FILTERING is true.
    #
    # @param [Integer]  severity
    # @param [any, nil] message
    # @param [any, nil] progname      Default @progname
    #
    # @return [TrueClass]
    #
    def add(severity, message = nil, progname = nil)
      return true if ::Logger.suppressed? || (severity < level)
      if message.nil?
        if block_given?
          message = yield
        else
          message, progname = [progname, nil]
        end
      end
      # noinspection RubyMismatchedReturnType
      filter_out?(message) or super
    end

    # =========================================================================
    # :section: ActiveSupport::LoggerSilence overrides
    # =========================================================================

    public

    # Silences the logger for the duration of the block unless logging is
    # already suppressed.
    #
    # @param [Integer, Symbol, nil] severity
    #
    # return [any, nil]
    #
    def silence(severity = Logger::ERROR)
      ::Logger.suppressed? ? yield(self) : super
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # Regexp fragment for matching an ANSI color sequence.
    #
    # @type [String]
    #
    ANSI_COLOR = ("\e" + '\[\d+m').freeze

    # Regexp fragment for matching the start of a log message which may or may
    # not have been colorized.
    #
    # @type [String]
    #
    START = "^\\s*(#{ANSI_COLOR})*"

    # Patterns of log entries which are not helpful and/or way too frequent.
    #
    # @type [Array<Regexp>]
    #
    FILTER_OUT = [
      /#{START}GoodJob::Execution Load/,
      /#{START}GoodJob::Lockable Unlock/,
      /#{START}Processing by HealthController#check/,
    ].freeze

    # Indicate whether the given log entry should be skipped if log output is
    # going to AWS CloudWatch.
    #
    # @param [any, nil] message
    #
    def filter_out?(message)
      message.is_a?(String) && FILTER_OUT.any? { |expr| expr.match?(message) }
    end
      .tap { |meth| neutralize(meth) unless FILTERING }

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Ensure that every log line is prefixed with the same log information to
    # facilitate filtering.
    #
    class Formatter < ::Logger::Formatter

      # Width of severity column.
      #
      # @type [Integer]
      #
      SEV = 5

      # Width of progname column.
      #
      # @type [Integer]
      #
      PRG = 4

      # Character used for filling out fixed-width columns for AWS format.
      #
      # @type [String]
      #
      AWS_FILL = '_'

      # Time not shown in favor of the CloudWatch timestamp.
      #
      # @type [String]
      #
      AWS_LEADER =              "[%<pid>d] %<sev>-#{SEV}s -- %<prg>-#{PRG}s: "

      # Like Logger::Formatter::Format but with the progname aligned.
      #
      # @type [String]
      #
      STD_LEADER =
                "%{chr}, [%{tim} #%<pid>d] %<sev>-#{SEV}s -- %<prg>-#{PRG}s: "

      # =======================================================================
      # :section: Logger::Formatter overrides
      # =======================================================================

      public

      # Format for local or AWS CloudWatch logging.
      #
      # @param [String, Integer] severity
      # @param [Time]            time
      # @param [any, nil]        progname
      # @param [any, nil]        msg
      #
      # @return [String]
      #
      # @see #aws_leader
      # @see #std_leader
      #
      def call(severity, time, progname, msg)
        ldr = leader(severity, time, progname)
        msg2str(msg).split("\n").map { |txt| "#{ldr}#{txt}\n" }.join
      end

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # Format for AWS CloudWatch logging.
      #
      # Because the collapsed view of log lines squeezes out multiple spaces,
      # fixed-width columns are right-filled with #AWS_FILL as needed.
      #
      # @param [String, Integer] severity
      # @param [Time]            _time
      # @param [any, nil]        progname
      #
      # @return [String]
      #
      def aws_leader(severity, _time, progname)
        AWS_LEADER % {
          pid: Process.pid,
          sev: right_fill(severity, SEV),
          prg: right_fill(progname, PRG),
        }
      end

      # Format for local logging.
      #
      # @param [String, Integer] severity
      # @param [Time]            time
      # @param [any, nil]        progname
      #
      # @return [String]
      #
      def std_leader(severity, time, progname)
        STD_LEADER % {
          chr: severity[0..0],
          tim: format_datetime(time),
          pid: Process.pid,
          sev: severity,
          prg: right_fill(progname, PRG, ' '),
        }
      end

      if AWS_FORMATTING
        alias leader aws_leader
      else
        alias leader std_leader
      end

      # Right-fill *item* if necessary so that its representation has at least
      # *width* characters.
      #
      # @param [any, nil] item
      # @param [Integer]  width
      # @param [String]   char
      #
      # @return [String]
      #
      def right_fill(item, width, char = AWS_FILL)
        item  = item.to_s
        part  = item.split(':')
        tag   = part.shift || +''
        fill  = width - tag.size
        tag  << char * fill if fill.positive?
        part << nil         if item.end_with?(':')
        [tag, *part].join(':')
      end

    end

  end

end

__loading_end(__FILE__)
