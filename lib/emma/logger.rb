# lib/emma/loggger.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Emma

  # Application logger.
  #
  class Logger < ::Logger

    FILTERING =
      if application_deployed?
        !false?(ENV['EMMA_LOG_FILTERING'])
      else
        true?(ENV['EMMA_LOG_FILTERING'])
      end

    AWS_FORMATTING =
      if application_deployed?
        !false?(ENV['EMMA_LOG_AWS_FORMATTING'])
      else
        true?(ENV['EMMA_LOG_AWS_FORMATTING'])
      end

    # =========================================================================
    # :section: Logger overrides
    # =========================================================================

    public

    def initialize(*arg, **opt)
      super(*arg, **opt)
      @default_formatter = Formatter.new
    end

    # Prefix all lines with the same leading log information, and reduce log
    # entries if #FILTERING is true.
    #
    # @param [Integer] severity
    # @param [*]       message
    # @param [*]       progname       Default @progname
    #
    # @return [TrueClass]
    #
    def add(severity, message = nil, progname = nil)
      return true if severity && (severity < level)
      if message.nil?
        if block_given?
          message = yield
        else
          message, progname = [progname, nil]
        end
      end
      # noinspection RubyMismatchedReturnType
      filter_out?(message) or super(severity, message, progname)
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
    ].freeze

    # Indicate whether the given log entry should be skipped if log output is
    # going to AWS CloudWatch.
    #
    # @param [*] message
    #
    def filter_out?(message)
      message.is_a?(String) && FILTER_OUT.any? { |expr| expr.match?(message) }
    end

    neutralize(:filter_out?) unless FILTERING

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Ensure that every log line is prefixed with the same log information to
    # facilitate filtering.
    #
    class Formatter < ::Logger::Formatter

      # Time not shown in favor of the CloudWatch timestamp.
      #
      # @type [String]
      #
      AWS_FORMAT = "[%d] %5s -- %4s: %s\n"

      # The same as Logger::Formatter::Format but with the progname aligned.
      #
      # @type [String]
      #
      BASIC_FORMAT = "%s, [%s #%d] %5s -- %4s: %s\n"

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Format for AWS CloudWatch logging.
      #
      # @param [Integer] severity
      # @param [Time]    _time
      # @param [String]  progname
      # @param [*]       msg
      #
      # @return [String]
      #
      # @see #AWS_FORMAT
      #
      def aws_call(severity, _time, progname, msg)
        pid = Process.pid
        msg2str(msg).split("\n").map { |line|
          AWS_FORMAT % [pid, severity, progname, line]
        }.join
      end

      # Format for local logging.
      #
      # @param [Integer] severity
      # @param [Time]    time
      # @param [String]  progname
      # @param [*]       msg
      #
      # @return [String]
      #
      # @see #BASIC_FORMAT
      #
      def basic_call(severity, time, progname, msg)
        time = format_datetime(time)
        char = severity[0..0]
        pid  = Process.pid
        msg2str(msg).split("\n").map { |line|
          BASIC_FORMAT % [char, time, pid, severity, progname, line]
        }.join
      end

      if AWS_FORMATTING
        alias call aws_call
      else
        alias call basic_call
      end

    end

  end

end

__loading_end(__FILE__)
