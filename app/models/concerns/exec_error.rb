# app/models/concerns/exec_error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for augmented application errors.
#
class ExecError < RuntimeError

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Placeholder error message.
  #
  # @type [String]
  #
  DEFAULT_ERROR = I18n.t('emma.error._default', default: 'unknown').freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Individual error messages (if the originator supplied multiple messages).
  #
  # @return [Array<String>]
  #
  attr_reader :messages

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Array<Exception, Hash, String, nil>] args
  # @param [Hash]                                opt
  #
  # === Implementation Notes
  # Each element of @messages is duplicated in order to ensure that there are
  # no unexpected entanglements with the original message source(s).
  #
  def initialize(*args, **opt)
    @messages ||= []  # May have been initialized by the subclass.
    @cause    ||= nil # May have been set by the subclass.
    args.each do |arg|
      case arg
        when Exception then @messages.concat extract_message((@cause ||= arg))
        when Hash      then @messages.concat extract_message(arg)
        when Array     then @messages.concat arg
        when String    then @messages << arg
        else Log.warn { "ExecError#initialize: #{arg.inspect} ignored" } if arg
      end
    end
    @messages.remove extract_message(opt) if opt.present?
    case @cause
      when nil
        # Ignore
      when ExecError
        @messages.concat @cause.messages
        @cause = @cause.cause || @cause
      when Faraday::Error
        @messages.remove Array.wrap(@cause.message)
      when Exception
        @messages.concat Array.wrap(@cause.message)
      else
        Log.warn { "ExecError#initialize: @cause #{@cause.class} unexpected" }
    end
    @messages.compact_blank!
    @messages << default_message if @messages.empty?
    @messages.uniq!
    @messages.map! { |m| to_utf8(m).tap { |v| (m == v) ? v.dup : v } }
    # noinspection RubyMismatchedArgumentType
    super(@messages.first)
  rescue => error
    Log.error { "ExecError#initialize: #{error.class}: #{error.message}" }
    re_raise_if_internal_exception(error)
    super('ERROR')
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Indicate that the instance has no messages.
  #
  def blank?
    messages.blank?
  end

  # ===========================================================================
  # :section: Exception overrides
  # ===========================================================================

  public

  # To satisfy Kernel#raise this returns the instance itself.
  #
  # @return [Exception]
  #
  def exception(...)
    self
  end

  # If applicable, the original exception that was rescued which resulted in
  # raising an ExecError exception.
  #
  # @return [Exception, nil]
  #
  def cause
    @cause
  end

  # Execution stack associated with the original exception.
  #
  # @return [Array<String>, nil]
  #
  def backtrace
    cause&.backtrace || super
  end

  # inspect
  #
  # @return [String]
  #
  def inspect
    items = {
      cause: ApiHelper.format_api_result(@cause, html: false),
    }.map { |k, v| "@#{k}=#{v}" }.join(', ')
    '#<%s: %s %s>' % [self.class, message, items]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods to be included in related subclasses.
  #
  module Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Fallback error message.
    #
    # @return [String]
    #
    def default_message(...)
      DEFAULT_ERROR
    end

    # Extract error message(s) from the given item.
    #
    # @param [Any] src
    #
    # @return [Array<String>]
    #
    def extract_message(src)
      Array.wrap(src).map(&:to_s)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include Methods

end

__loading_end(__FILE__)
