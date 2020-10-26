# app/records/concerns/api/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for API errors.
#
class Api::Error < RuntimeError

  include Emma::Json
  include ExplorerHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If applicable, the HTTP response that resulted in the original exception.
  #
  # @return [Faraday::Response, nil]
  #
  attr_reader :response

  # If applicable, the HTTP status for the received message that resulted in
  # the original exception.
  #
  # @return [Integer, nil]
  #
  attr_reader :http_status

  # Individual error messages (if the originator supplied multiple messages).
  #
  # @return [Array<String>]
  #
  attr_reader :messages

  # Initialize a new instance.
  #
  # @param [Array<Faraday::Response, Exception, Integer, String, true, nil>] args
  # @param [String, nil] default      Default message.
  #
  def initialize(*args, default: nil)
    @response = @http_status = @cause = nil
    @messages = []
    args.each do |arg|
      case arg
        when Faraday::Response then @response    = arg
        when Exception         then @cause       = arg
        when Integer           then @http_status = arg
        when String            then @messages << arg
        when Array             then @messages += arg
        when true              then # Use default error message.
        when nil               then # Ignore silently.
        else Log.warn { "Api::Error#initialize: #{arg.inspect} ignored" }
      end
    end
    # noinspection RubyCaseWithoutElseBlockInspection, RubyNilAnalysis
    case @cause
      when Api::Error
        @messages     += @cause.messages
        @http_status ||= @cause.http_status
        @response    ||= @cause.response
        @cause         = @cause.cause
      when Faraday::Error
        @messages     += faraday_error(*@cause.message)
        @http_status ||= @cause.response&.dig(:status)
        @cause         = @cause.wrapped_exception
      when Exception
        @messages     += Array.wrap(@cause.message)
        @http_status ||= @response&.status
    end
    @messages.reject!(&:blank?)
    @messages.uniq!
    @messages << (default || default_message) if @messages.empty?
    super(@messages.first)
  rescue
    super('ERROR')
  end

  # ===========================================================================
  # :section: Exception overrides
  # ===========================================================================

  public

  # To satisfy Kernel#raise this returns the instance itself.
  #
  # @return [Exception]
  #
  def exception(*)
    self
  end

  # A fall-back for returning #messages as a single string.
  #
  # @param [String] connector         Connector between multiple messages.
  #
  # @return [String]
  #
  def to_s(connector: ', ')
    @messages.join(connector)
  end

  # A fall-back for returning #messages as a single string.
  #
  # @return [String]
  #
  def message
    to_s
  end

  # inspect
  #
  # @return [String]
  #
  def inspect
    items = {
      http_status: @http_status.inspect,
      response:    @response.inspect,
      cause:       api_format_result(@cause, html: false, indent: 2),
    }.map { |k, v| "@#{k}=#{v}" }.join(', ')
    '#<%s: %s %s>' % [self.class, message, items]
  end

  # Execution stack associated with the original exception.
  #
  # @return [Array<String>, nil]
  #
  def backtrace
    cause&.backtrace || super
  end

  # If applicable, the original exception that was rescued which resulted in
  # raising an Api::Error exception.
  #
  # @return [Exception, nil]
  #
  def cause
    @cause
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Enhance Faraday::Error messages.
  #
  # @param [Array<String>] messages
  #
  # @return [Array<String>]
  #
  def faraday_error(*messages)
    messages.map do |m|
      m.sub(/status (\d+)/) do |s|
        description = Net::HTTP::STATUS_CODES[$1.to_i]
        description ? "#{s} (#{description})" : s
      end
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  module Methods

    def self.included(base)
      base.send(:extend, self)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Name of the service and key into config/locales/error.en.yml.
    #
    # @return [Symbol, nil]
    #
    # NOTE: To be overridden by the subclass of Api::Error
    #
    def service
    end

    # Name of the error and subkey into config/locales/error.en.yml.
    #
    # @return [Symbol, nil]
    #
    # NOTE: To be overridden by the subclass of Api::Error
    #
    def error_type
    end

    # The descriptive name of the service for use in display and messages.
    #
    # @param [Symbol, String, nil] source     Source repository
    #
    # @return [String]
    #
    def service_name(source: nil)
      source ||= service
      keys = []
      keys << :"emma.error.#{source}._name" if source
      keys << :'emma.error.api._name'
      keys << 'remote service'
      I18n.t(keys.shift, default: keys)
    end

    # Default error message for the current instance based on the name of its
    # class.
    #
    # @param [Symbol, String, nil] source     Source repository
    # @param [Symbol, String, nil] type       Error type.
    # @param [Boolean]             allow_nil
    #
    # @return [String]                The appropriate error message.
    # @return [nil]                   If *allow_nil* is set to *true* and no
    #                                   default message is defined.
    #
    # @see en.emma.error.api in config/locales/error.en.yml
    #
    def default_message(source: nil, type: nil, allow_nil: false)
      source ||= service
      type   ||= error_type
      name = service_name(source: source)
      opt  = { service: name, Service: name.upcase_first }
      keys = []
      keys << :"emma.error.#{source}.#{type}"       if source && type
      keys << :"emma.error.api.#{type}"             if type
      keys << :"emma.error.#{source}.default"       if source
      keys << :'emma.error.api.default'
      keys << "#{type&.capitalize || 'API'} error"  unless allow_nil
      I18n.t(keys.shift, default: keys, **opt)
    end

  end

  include Methods

end

__loading_end(__FILE__)
