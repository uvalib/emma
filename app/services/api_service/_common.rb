# app/services/api_service/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/https'
require 'faraday'

class ApiService

  module Common

    # OAuth2 authorization type.
    #
    # @type [String]
    #
    AUTH_TYPE = ENV['BOOKSHARE_AUTH_TYPE'] || 'token'
    #AUTH_TYPE = 'code'

    # OAuth2 grant type.
    #
    # @type [String]
    #
    GRANT_TYPE = ENV['BOOKSHARE_GRANT_TYPE'] || 'authorization_code'
    #GRANT_TYPE = 'password'

    # NOTE: only for GRANT_TYPE == 'password'
    #
    # @type [String]
    #
    USERNAME = ENV['TEST_USERNAME']

    # NOTE: only for GRANT_TYPE == 'password'
    #
    # @type [String]
    #
    PASSWORD = ENV['TEST_PASSWORD'] || USERNAME

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
      @exception = @response = nil
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

    rescue SocketError, EOFError => error
      @exception = error
      raise error # Handled by ApplicationController

    rescue => error
      __debug { "!!! #{__method__} | #{action.inspect} | ERROR: #{error.message}" }
      Log.error { "API #{__method__}: #{error.message}" }
      @exception = error
      return nil # To be handled in the calling method.

    ensure # TODO: remove
      __debug { "<<< #{__method__} | #{action.inspect} | data = #{@response&.body.inspect.truncate(256)}" }

    end

    # Send/receive OAuth messages.
    #
    # @param [Array<String>] args       Path components to the Bookshare API.
    #
    # args[0]   [String]  Path component.
    # ...
    # args[-2]  [String]  Path component.
    # args[-1]  [Hash]    Post body data.
    #
    # @return [Faraday::Response]
    #
    def oauth(*args)
      #@exception = nil # TODO: restore
      @exception = oauth_response = nil # TODO: remove
      params = {}
      params.merge!(args.pop) if args.last.is_a?(Hash)
      args.unshift('oauth') unless args.first == 'oauth'
      action = args.join('/').strip
      action = "/#{action}" unless action.start_with?('/')
      type   = params[:grant_type] || GRANT_TYPE
      __debug { ">>> #{__method__} | #{action.inspect} | params = #{params.inspect}" }
      #make_connection(type).post(action,  params) # TODO: restore
      oauth_response = make_connection(type).post(action,  params) # TODO: remove

    rescue SocketError, EOFError => error
      __debug { "!!! #{__method__} | #{action.inspect} | rescue1: #{error.message}" }
      @exception = error
      raise error # Handled by ApplicationController

    rescue => error
      __debug { "!!! #{__method__} | #{action.inspect} | rescue2: #{error.message}" }
      Log.error { "API #{__method__}: #{error.message}" }
      @exception = error
      return nil # To be handled in the calling method.

    ensure # TODO: remove
      __debug { "<<< #{__method__} | #{action.inspect} | response = #{oauth_response.inspect}" }

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
    # @param [Api::GrantType, nil] oauth
    #
    # @return [Faraday::Connection]
    #
    def make_connection(oauth = nil)
      conn_opts = { request: options.slice(:timeout, :open_timeout) }
      if oauth
        conn_opts[:url] = auth_url
      else
        conn_opts[:url] = base_url
        conn_opts[:request][:params_encoder] = Faraday::FlatParamsEncoder
      end

      retry_opt = {
        max:                 options[:retry_after_limit],
        interval:            0.05,
        interval_randomness: 0.5,
        backoff_factor:      2,
      }

      logger_opt = {}
      logger_opt[:bodies] = true if oauth

      passwd = (oauth == 'password') || (GRANT_TYPE == 'password')
      token  = (@access_token.presence unless passwd)

      Faraday.new(conn_opts) do |conn|
        conn.use           :api_caching_middleware  if CACHING && !oauth
        conn.basic_auth    API_KEY, ''              if passwd
        conn.authorization :Bearer, token           if token
        conn.request       :url_encoded             if oauth
        conn.request       :retry, retry_opt
        conn.response      :logger, Rails.logger, logger_opt
        conn.response      :raise_error
        conn.adapter       options[:adapter] || Faraday.default_adapter
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

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
