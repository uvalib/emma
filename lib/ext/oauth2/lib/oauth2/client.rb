# lib/ext/oauth2/lib/oauth2/client.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the OAuth2 gem.

=begin # NOTE: OAuth2 disabled
__loading_begin(__FILE__)

require 'oauth2/client'

module OAuth2

  # Override definitions to be prepended to OAuth2::Client.
  #
  # @!attribute [r] id
  #   @return [String]
  #
  # @!attribute [r] secret
  #   @return [String]
  #
  # @!attribute [r] site
  #   @return [String]
  #
  # @!attribute options
  #   @return [Hash]
  #
  module ClientExt

    include Emma::Common

    include OAuth2::ExtensionDebugging

    # =========================================================================
    # :section: OAuth2::Client overrides
    # =========================================================================

    public

    # Instantiate a new OAuth 2.0 client using the Client ID and Client
    # Secret registered to your application.
    #
    # @param [String] client_id
    # @param [String] client_secret
    # @param [Hash]   options
    # @param [Proc]   blk             @see OAuth2::Client#initialize
    #
    # @option options [String]  :site             The OAuth2 provider site
    #                                             host.
    #
    # @option options [String]  :redirect_uri     The absolute URI to the
    #                                             Redirection Endpoint for
    #                                             use in authorization grants
    #                                             and token exchange.
    #
    # @option options [String]  :authorize_url    Absolute or relative URL
    #                                             path to the Authorization
    #                                             endpoint.
    #                                             Default: '/oauth/authorize'
    #
    # @option options [String]  :token_url        Absolute or relative URL
    #                                             path to the Token endpoint.
    #                                             Default: '/oauth/token'
    #
    # @option options [Symbol]  :token_method     HTTP method to use to
    #                                             request the token.
    #                                             Default: :post
    #
    # @option options [Symbol]  :auth_scheme      Method to use to authorize
    #                                             request: :basic_auth or
    #                                             :request_body (default).
    #
    # @option options [Hash]    :connection_opts  Hash of connection options
    #                                             to pass to initialize
    #                                             Faraday.
    #
    # @option options [FixNum]  :max_redirects    Maximum number of redirects
    #                                             to follow. Default: 5.
    #
    # @option options [Boolean] :raise_errors     If *false*, 400+ response
    #                                             statuses do not raise
    #                                             OAuth2::Error.
    #
    # @option options [Logger]  :logger           Logger to use when
    #                                             OAUTH_DEBUG is enabled.
    #
    # @option options [Proc]    :extract_access_token
    #                                             Proc that extracts the
    #                                             access token from the
    #                                             response.
    #
    def initialize(client_id, client_secret, options = {}, &blk)
      super
      @options[:logger] = Log.new(progname: 'OAUTH2') unless options[:logger]
      @options[:logger].level = DEBUG_OAUTH ? Log::DEBUG : Log::INFO
      @options[:revoke_url]   = '/oauth/revocations'
    end

    # Makes a request relative to the specified site root.
    #
    # @param [Symbol] verb                One of :get, :post, :put, :delete.
    # @param [String] url                 URL path of request.
    # @param [Hash]   opts                The options to make the request with.
    #
    # @option opts [Hash]         :params   Added request query parameters.
    # @option opts [Hash, String] :body     The body of the request.
    # @option opts [Hash]         :headers  HTTP request headers.
    # @option opts [Boolean] :raise_errors  If *true*, raise OAuth2::Error on
    #                                         400+ response status.
    #                                         Default: `options[:raise_errors]`
    # @option opts [Symbol]       :parse    @see Response#initialize
    #
    # @raise [OAuth2::Error]              For 400+ response status.
    #
    # @return [OAuth2::Response]
    #
    # @yield [req] Gives access to the request before it is transmitted.
    # @yieldparam [Faraday::Request] req  The Faraday request.
    # @yieldreturn [void]                 The block accesses *req* directly.
    #
    # === Implementation Notes
    # The original code had a problem in setting :logger here (repeatedly);
    # this has been moved to #connection so that it happens only once.
    #
    # @see OmniAuth::Strategies::Bookshare#request_phase
    #
    def request(verb, url, opts = {})
      __ext_debug(binding)
      body = opts[:body]
      body = opts[:body] = url_query(body) if body.is_a?(Hash)
      hdrs = opts[:headers]
      prms = opts[:params]
      url  = connection.build_url(url).to_s

      response =
        connection.run_request(verb, url, body, hdrs) do |req|
          req.params.update(prms) if prms.present?
          __ext_debug(verb.to_s.upcase, url, req.params)
          yield(req) if block_given?
        end
      __ext_debug('RESPONSE', response)
      response = Response.new(response, opts.slice(:parse))

      case response.status

        when 301, 302, 303, 307
          # Redirect, or keep this response if beyond the limit of redirects.
          __ext_debug("REDIRECT #{response.status}")
          opts[:redirect_count] ||= 0
          opts[:redirect_count] += 1
          if (max = options[:max_redirects]) && (opts[:redirect_count] <= max)
            if response.status == 303
              verb = :get
              opts.delete(:body)
            end
            url = response.headers['Location'].to_s
            response = request(verb, url, opts)
          end

        when 200..299, 300..399
          # On non-redirecting 3xx statuses, just return the response.
          __ext_debug("REDIRECT #{response.status}")

        when 400..599
          # Server error.
          __ext_debug("ERROR #{response.status}")
          error = Error.new(response)
          raise(error) if opts.fetch(:raise_errors, options[:raise_errors])
          response.error = error

        else
          # Other error.
          __ext_debug("UNEXPECTED #{response.status}")
          error = Error.new(response)
          raise(error, "Unhandled status code value of #{response.status}")

      end
      response
    end

    # The redirect_uri parameters dynamically assigned in
    # OmniAuth::Strategies::Bookshare#client.
    #
    # @return [Hash]
    #
    def redirection_params
      options.slice(:redirect_uri).stringify_keys
    end

    # =========================================================================
    # :section: OAuth2::Client overrides
    # =========================================================================

    protected

    # Include the response with logger output.
    #
    # @param [Faraday::RackBuilder] builder
    #
    def oauth_debug_logging(builder)
      return unless DEBUG_OAUTH
      log_options = { bodies: { request: true, response: DEBUG_OAUTH } }
      builder.response :logger, options[:logger], log_options
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Revoke the token (to end the session).
    #
    # @param [OAuth2::AccessToken, Hash, String] token
    # @param [Hash, nil] params       Additional query parameters.
    # @param [Hash, nil] opts         Options.
    #
    # @return [OAuth2::Response]
    # @return [nil]                   If no token was provided or found.
    #
    def revoke_token(token, params = nil, opts = nil)
      case token
        when OAuth2::AccessToken
          token = token.token
        when Hash
          h = token.deep_symbolize_keys
          token = h[:access_token] || h[:token] || h.dig(:credentials, :token)
      end
      if token.blank?
        Log.warn("#{__method__}: no token")
        return
      end

      # Prepare data values including the token.
      meth   = options[:token_method]
      auth   = Authenticator.new(id, secret, options[:auth_scheme])
      params = auth.apply(params || {}).merge!(token: token)

      # Prepare headers and other options.
      opts    = opts&.dup || {}
      headers = opts[:headers]&.dup || {}
      headers.merge!(params.delete(:headers) || {})
      if meth == :get
        opts[:params] = params
      else
        opts[:body] = params
        headers['Content-Type'] = 'application/x-www-form-urlencoded'
      end
      opts[:headers] = headers
      opts[:raise_errors] = false unless opts.key?(:raise_errors)

      request(meth, options[:revoke_url], opts)
    end

  end

  if DEBUG_OAUTH

    # Overrides adding extra debugging around method calls.
    #
    module ClientDebug

      include OAuth2::ExtensionDebugging

      # Non-functional hints for RubyMine type checking.
      # :nocov:
      unless ONLY_FOR_DOCUMENTATION
        include OAuth2::ClientExt
      end
      # :nocov:

      # =======================================================================
      # :section: OAuth2::Client overrides
      # =======================================================================

      public

      # Instantiate a new OAuth 2.0 client using the Client ID and Client
      # Secret registered to your application.
      #
      # @param [String] client_id
      # @param [String] client_secret
      # @param [Hash]   options
      # @param [Proc]   blk             @see OAuth2::Client#initialize
      #
      # @option options [String]  :site             The OAuth2 provider site
      #                                             host.
      #
      # @option options [String]  :redirect_uri     The absolute URI to the
      #                                             Redirection Endpoint for
      #                                             use in authorization grants
      #                                             and token exchange.
      #
      # @option options [String]  :authorize_url    Absolute or relative URL
      #                                             path to the Authorization
      #                                             endpoint.
      #                                             Default: '/oauth/authorize'
      #
      # @option options [String]  :token_url        Absolute or relative URL
      #                                             path to the Token endpoint.
      #                                             Default: '/oauth/token'
      #
      # @option options [Symbol]  :token_method     HTTP method to use to
      #                                             request the token.
      #                                             Default: :post
      #
      # @option options [Symbol]  :auth_scheme      Method to use to authorize
      #                                             request: :basic_auth or
      #                                             :request_body (default).
      #
      # @option options [Hash]    :connection_opts  Hash of connection options
      #                                             to pass to initialize
      #                                             Faraday.
      #
      # @option options [FixNum]  :max_redirects    Maximum number of redirects
      #                                             to follow. Default: 5.
      #
      # @option options [Boolean] :raise_errors     If *false*, 400+ response
      #                                             statuses do not raise
      #                                             OAuth2::Error.
      #
      # @option options [Logger]  :logger           Logger to use when
      #                                             OAUTH_DEBUG is enabled.
      #
      # @option options [Proc]    :extract_access_token
      #                                             Proc that extracts the
      #                                             access token from the
      #                                             response.
      #
      def initialize(client_id, client_secret, options = {}, &blk)
        __ext_debug(binding)
        super
      end

      # The authorize endpoint URL of the OAuth2 provider
      #
      # @param [Hash] params            Additional query parameters.
      #
      # @return [String]
      #
      def authorize_url(params = {})
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # The token endpoint URL of the OAuth2 provider
      #
      # @param [Hash] params            Additional query parameters.
      #
      # @return [String]
      #
      def token_url(params = nil)
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # Initializes an AccessToken by making a request to the token endpoint.
      #
      # @param [Hash]  params                 For the token endpoint.
      # @param [Hash]  access_token_opts      Passed to the AccessToken object.
      # @param [Class] extract_access_token   Class of access token for easier
      #                                         OAuth2::AccessToken subclassing
      #
      # @return [AccessToken]         The initialized AccessToken.
      #
      def get_token(
        params,
        access_token_opts    = {},
        extract_access_token = options[:extract_access_token]
      )
        __ext_debug(binding)
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # The Authorization Code strategy
      #
      # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.1
      #
      def auth_code
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # The Implicit strategy
      #
      # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-26#section-4.2
      #
      def implicit
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # The Resource Owner Password Credentials strategy
      #
      # @return [OAuth2::Strategy::Password]
      #
      # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.3
      #
      def password
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # The Client Credentials strategy
      #
      # @return [OAuth2::Strategy::ClientCredentials]
      #
      # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.4
      #
      def client_credentials
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # The Client Assertion Strategy
      #
      # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-10#section-4.1.3
      #
      def assertion
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Revoke the token (to end the session).
      #
      # @param [OAuth2::AccessToken, Hash, String] token
      # @param [Hash, nil] params       Additional query parameters.
      # @param [Hash, nil] opts         Options.
      #
      # @return [OAuth2::Response]
      # @return [nil]                   If no token was provided or found.
      #
      def revoke_token(token, params = nil, opts = nil)
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::Client => OAuth2::ClientExt
override OAuth2::Client => OAuth2::ClientDebug if DEBUG_OAUTH

__loading_end(__FILE__)
=end
