# app/records/concerns/api/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http/status'

# Base exception for API errors.
#
class Api::Error < ExecError

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If applicable, the HTTP response that resulted in the original exception.
  #
  # @return [Faraday::Response, nil]
  #
  attr_reader :http_response

  # If applicable, the HTTP status for the received message that resulted in
  # the original exception.
  #
  # @return [Integer, nil]
  #
  attr_reader :http_status

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Array<Faraday::Response,Exception,Hash,String,Integer,nil>] args
  # @param [Hash]                                                       opt
  #
  # == Implementation Notes
  # Each element of @messages is duplicated in order to ensure that there are
  # no unexpected entanglements with the original message source(s).
  #
  def initialize(*args, **opt)
    @http_response = @http_status = @cause = nil
    args.map! do |arg|
      case arg
        when Integer           then (@http_status = arg) and next
        when Exception         then @cause = arg
        when Faraday::Response then faraday_response(arg)
        else                        arg
      end
    end
    args.flatten!
    args.compact!
    # noinspection RubyNilAnalysis, RailsParamDefResolve
    case @cause
      when nil
        # Ignore
      when Api::Error
        @http_response ||= @cause.http_response
        @http_status   ||= @cause.http_status
      when Faraday::Error
        @http_status   ||= @cause.response&.dig(:status)
        args             = faraday_error(*@cause.message) + args
        @cause           = @cause.wrapped_exception || @cause
      when Exception
        @http_status   ||= @cause.try(:code)
      else
        Log.warn { "Api::Error#initialize: @cause #{@cause.class} unexpected" }
    end
    @http_status ||= @http_response&.status
    super(*args, **opt)
  rescue => error
    Log.error { "Api::Error#initialize: #{error.class}: #{error.message}" }
    re_raise_if_internal_exception(error)
    super('ERROR')
  end

  # ===========================================================================
  # :section: Exception overrides
  # ===========================================================================

  public

  # inspect
  #
  # @return [String]
  #
  def inspect
    items = {
      http_status:   @http_status.inspect,
      http_response: @http_response.inspect,
      cause:         ApiHelper.format_api_result(@cause, html: false),
    }.map { |k, v| "@#{k}=#{v}" }.join(', ')
    '#<%s: %s %s>' % [self.class, message, items]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract Faraday::Response messages.
  #
  # @param [Faraday::Response] arg
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # As a side-effect, if @http_response is nil it will be set here.
  #
  def faraday_response(arg)
    @http_response ||= arg
    extract_message(arg)
  end

  # Enhance Faraday::Error messages.
  #
  # @param [Array<String>] messages
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # As a side-effect, if @http_status is nil and HTTP status can be determined,
  # then @http_status will be set here.
  #
  def faraday_error(*messages)
    messages.map { |m|
      next if (m = m.to_s.strip).blank?
      m.sub(/status (\d+)/) do |status|
        code = positive($1)
        @http_status ||= code if code
        description = code && Net::HTTP::STATUS_CODES[code]
        description ? "#{status} (#{description})" : status
      end
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods to be included in related subclasses.
  #
  module Methods

    include ExecError::Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Name of the service and key into config/locales/error.en.yml.
    #
    # @return [Symbol, nil]
    #
    def service
      @service ||=
        if (c = is_a?(Class) ? self : self.class)
          name = c.safe_const_get(:SERVICE_NAME)
          name ||= c.module_parent_name.underscore.remove(/_service$/)
          name&.to_sym || super
        end
    end

    # Name of the error and subkey into config/locales/error.en.yml.
    #
    # @return [Symbol, nil]
    #
    def error_type
      @error_type ||=
        if (c = is_a?(Class) ? self : self.class)
          type = c.safe_const_get(:ERROR_TYPE)
          type ||= c.name&.demodulize&.to_s&.underscore&.remove(/_error$/)
          type&.to_sym
        end
    end

    # Error configuration extracted from "config/locales/error.en.yml".
    #
    # @return [Hash{Symbol=>String}]
    #
    def error_config
      @error_config ||=
        [:api, service].compact.reduce({}) do |result, config_section|
          # noinspection RubyMismatchedArgumentType
          result.merge!(I18n.t("emma.error.#{config_section}", default: {}))
        end
    end

    # Error types extracted from "config/locales/error.en.yml".
    #
    # (Entries whose names start with '_' are excluded).
    #
    # @return [Array<Symbol>]
    #
    def error_types
      @error_types ||= error_config.keys.reject { |k| k.start_with?('_') }
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

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
      # noinspection RubyMismatchedReturnType
      I18n.t(keys.shift, default: keys)
    end

    # =========================================================================
    # :section: ExecError::Methods overrides
    # =========================================================================

    public

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
    # @see file:config/locales/error.en.yml *en.emma.error.api*
    #
    def default_message(source: nil, type: nil, allow_nil: false)
      source ||= service
      type   ||= error_type
      name = service_name(source: source)
      opt  = { service: name, Service: name.upcase_first }
      keys = []
      keys << :"emma.error.#{source}.#{type}"       if source && type
      keys << :"emma.error.api.#{type}"             if type
      keys << :"emma.error.#{source}._default"      if source
      keys << :'emma.error.api._default'
      keys << "#{type&.capitalize || 'API'} error"  unless allow_nil
      I18n.t(keys.shift, default: keys, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  include Methods

end

__loading_end(__FILE__)
