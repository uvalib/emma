# app/services/api_service/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/https'
require 'faraday'

class ApiService

  module Common

    # Control whether information requests are ever cached.
    #
    # @type [Boolean]
    #
    CACHING = false
    #CACHING = true

    # @type [Hash{Symbol=>String}]
    API_RECV_MESSAGE = {
      default: 'Bad response from server',
    }.freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    API_RECV_RESPONSE = {
      default: nil
    }.freeze

    # @type [Hash{Symbol=>String}]
    API_SEND_MESSAGE = {
      default: 'Bad response from server',
    }.freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    API_SEND_RESPONSE = {
      default: nil
    }.freeze

    # @type [Hash{Symbol=>Array<Symbol>}]
    REQUIRED_PARAMETERS = {
      create_account:        %i[firstName lastName emailAddress address1 postalCode],
      create_subscription:   %i[startDate userSubscriptionType],
      create_user_agreement: %i[agreementType dateSigned printName],
      create_user_pod:       %i[disabilityType proofSource],
      update_subscription:   %i[startDate userSubscriptionType],
      update_user_pod:       %i[proofSource],
    }.deep_freeze

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # @return [User]
    attr_reader :user

    # Set the user for the current session.
    #
    # @param [User] u
    #
    # @return [void]
    #
    def set_user(u)
      @user = (u if u.is_a?(User))
    end

    # The current OAuth2 access bearer token.
    #
    # @return [String, nil]
    #
    def access_token
      @user&.access_token
    end

    # The current OAuth2 refresher token.
    #
    # @return [String, nil]
    #
    def refresh_token
      @user&.refresh_token
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Get data from the API and update @response.
    #
    # @param [Symbol]        verb       One of :get, :post, :put, :delete
    # @param [Array<String>] args       Path components to the Bookshare API.
    #
    # args[0]   [String]  Path component.
    # ...
    # args[-2]  [String]  Path component.
    # args[-1]  [Hash]    URL parameters.
    #
    # @return [Faraday::Response]
    #
    def api(verb, *args)
      result = @exception = @response = nil
      update = %i[put post patch].include?(verb)
      params = { api_key: API_KEY }
      params.merge!(args.pop) if args.last.is_a?(Hash)
      params = params.to_json if update
      args.unshift(API_VERSION) unless args.first == API_VERSION
      action  = args.join('/').strip
      action  = "/#{action}" unless action.start_with?('/')
      headers = {}
      headers['Content-Type'] = 'application/json' if update
      __debug { ">>> #{__method__} | #{action.inspect} | params = #{params.inspect} | headers = #{headers.inspect}" }
      @response = connection.send(verb, action, params, headers)
      if @response.body[0,64].downcase.include?('page not found')
        # NOTE: bad request but @response.status is 200
      else
        result = @response
      end

    rescue SocketError, EOFError => error
      @exception = error
      result = nil
      raise error # Handled by ApplicationController

    rescue => error
      __debug { "!!! #{__method__} | #{action.inspect} | ERROR: #{error.message}" }
      Log.error { "API #{__method__}: #{error.message}" }
      @exception = error
      result = nil # To be handled in the calling method.

    ensure # TODO: remove
      __debug { "<<< #{__method__} | #{action.inspect} | status = #{@response&.status} | data = #{@response&.body.inspect.truncate(256)}" }
      return result

    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Get a connection for making cached requests.
    #
    # @return [Faraday::Connection]
    #
    # @see Faraday::ApiCachingMiddleWare#initialize
    #
    def connection
      @connection ||= make_connection
    end

    # Get a connection.
    #
    # @param [String, nil] url        Default: `#base_url`
    #
    # @return [Faraday::Connection]
    #
    def make_connection(url = nil)
      conn_opts = {
        url:     (url || base_url),
        request: options.slice(:timeout, :open_timeout),
      }
      conn_opts[:request][:params_encoder] ||= Faraday::FlatParamsEncoder

      retry_opt = {
        max:                 options[:retry_after_limit],
        interval:            0.05,
        interval_randomness: 0.5,
        backoff_factor:      2,
      }

      Faraday.new(conn_opts) do |bld|
        bld.use           :api_caching_middleware if CACHING
        bld.authorization :Bearer, access_token if access_token.present?
        bld.request       :retry,  retry_opt
        bld.response      :logger, Log.logger
        bld.response      :raise_error
        bld.adapter       options[:adapter] || Faraday.default_adapter
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Extract the user name to be used for API parameters.
    #
    # @param [User, String] user
    #
    # @return [String]
    #
    def get_username(user)
      user.is_a?(Hash) ? user['uid'] : user.to_s
    end

    # Validate presence of required API parameters.
    #
    # @param [Symbol]             method
    # @param [Hash]               parameters
    # @param [Array<Symbol>, nil] required
    #
    # @raise RuntimeError
    #
    def validate_parameters(method, parameters, required = nil)
      required ||= REQUIRED_PARAMETERS[method]
      keys = Array.wrap(required).reject { |key| parameters[key] }
      return unless keys.present?
      params = 'parameter'.pluralize(keys.size)
      keys   = keys.join(', ')
      raise RuntimeError, "#{method} missing #{params} #{keys}"
    end

    # validate_response
    #
    # TODO: doesn't deal with all return codes
    #
    # @param [Faraday::Response, nil] response  Default: @response.
    #
    # @return [void]
    #
    def validate_response(response = nil)
      response ||= @response
      valid =
        case response&.status
          when 200..299
            response&.body&.present?
        end
      raise_exception(__method__) unless valid
    end

    # raise_exception
    #
    # @param [Symbol, String] method  For log messages.
    #
    def raise_exception(method)
      response_table = API_SEND_RESPONSE
      message_table  = API_SEND_MESSAGE
      message = request_error_message(method, response_table, message_table)
      raise Api::Error, message
    end

    # Produce an error message from an HTTP response.
    #
    # @param [Symbol, String]         method          For log messages.
    # @param [Hash, nil]              response_table
    # @param [Hash, nil]              template_table
    # @param [Net::HTTPResponse, nil] response        Default: @response.
    #
    # @return [String]
    #
    def request_error_message(
      method          = nil,
      response_table  = nil,
      template_table  = nil,
      response        = @response
    )
      # Extract information from the HTTP response.
      body    = response&.body&.presence
      error   = body && ApiError.new(body)
      code    = error&.code
      message = error&.message&.presence
      level   = message ? Logger::WARN : Logger::Error

      # Generate a message if one was not provided in the received data.
      message ||=
        if response.blank?
          'no HTTP result'
        elsif body.blank?
          'empty HTTP result body'
        else
          'unknown failure'
        end

      # Log the warning/error.
      Log.log(level) do
        log = ["API #{method}: #{message}"]
        log << "code #{code.inspect}"
        log << "body #{body}" if body.present?
        log.join('; ')
      end

      # Get the message template which matches *message*.
      template =
        if template_table.present?
          key =
            response_table&.find { |_, pattern|
              case pattern
                when nil    then true
                when String then message.include?(pattern)
                when Regexp then message =~ pattern
              end
            }&.first
          template_table[key] || template_table[:default]
        end

      # Include the message from received data.
      if template.blank?
        message
      elsif template.include?('%')
        template % message
      else
        "#{template}: #{message}"
      end
    end

  end

end

__loading_end(__FILE__)
