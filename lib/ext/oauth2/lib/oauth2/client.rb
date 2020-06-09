# lib/ext/oauth2/lib/oauth2/client.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the OAuth2 gem.

__loading_begin(__FILE__)

require 'oauth2/client'

module OAuth2

  # Override definitions to be prepended to OAuth2::Client.
  #
  # !@attribute [r] id
  #   @return [String]
  #
  # !@attribute [r] secret
  #   @return [String]
  #
  # !@attribute [r] site
  #   @return [String]
  #
  # !@attribute [rw] options
  #   @return [Hash]
  #
  module ClientExt

    include Emma::Common
    include Emma::Debug

    # =========================================================================
    # :section:
    # =========================================================================

    public

    OAUTH_DEBUG = true?(ENV['OAUTH_DEBUG'])

    # =========================================================================
    # :section: OAuth2::Client overrides
    # =========================================================================

    public

    # Instantiate a new OAuth 2.0 client using the Client ID and Client Secret
    # registered to your application.
    #
    # @param [String] client_id
    # @param [String] client_secret
    # @param [Hash]   options
    # @param [Proc]   block           @see OAuth2::Client#initialize
    #
    # @option options [String]  :site             The OAuth2 provider site host
    #
    # @option options [String]  :redirect_uri     The absolute URI to the
    #                                             Redirection Endpoint for use
    #                                             in authorization grants and
    #                                             token exchange.
    #
    # @option options [String]  :authorize_url    Absolute or relative URL path
    #                                             to the Authorization endpoint
    #                                             Default: '/oauth/authorize'.
    #
    # @option options [String]  :token_url        Absolute or relative URL path
    #                                             to the Token endpoint.
    #                                             Default: '/oauth/token'.
    #
    # @option options [Symbol]  :token_method     HTTP method to use to request
    #                                             the token. Default: :post.
    #
    # @option options [Symbol]  :auth_scheme      Method to use to authorize
    #                                             request: :basic_auth or
    #                                             :request_body (default).
    #
    # @option options [Hash]    :connection_opts  Hash of connection options to
    #                                             pass to initialize Faraday.
    #
    # @option options [FixNum]  :max_redirects    Maximum number of redirects
    #                                             to follow. Default: 5.
    #
    # @option options [Boolean] :raise_errors     If *false*, 400+ response
    #                                             statuses do not raise
    #                                             OAuth2::Error.
    #
    # This method overrides:
    # @see OAuth2::Client#initialize
    #
    def initialize(client_id, client_secret, options = {}, &block)
      __debug_args("OAUTH2 #{__method__}", binding)
      super
    end

    # The Faraday connection object.
    #
    # @return [Faraday::Connection]
    #
    # This method overrides:
    # @see OAuth2::Client#connection
    #
    # == Implementation Notes
    # This corrects the logic error of setting :logger repeatedly in #request
    # by setting it once here.
    #
    def connection
      @connection ||=
        Faraday.new(site, options[:connection_opts]) do |bld|
          log_options = { bodies: { request: true, response: OAUTH_DEBUG } }
          bld.response :logger, Log.logger, log_options
          if options[:connection_build]
            options[:connection_build].call(bld)
          else
            bld.adapter Faraday.default_adapter
          end
        end
    end

    # The authorize endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params            Additional query parameters.
    #
    # @return [String]
    #
    # This method overrides:
    # @see OAuth2::Client#authorize_url
    #
    def authorize_url(params = {})
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The token endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params            Additional query parameters.
    #
    # @return [String]
    #
    # This method overrides:
    # @see OAuth2::Client#token_url
    #
    def token_url(params = nil)
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
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
    # This method overrides:
    # @see OAuth2::Client#request
    #
    # == Implementation Notes
    # The original code had a problem in setting :logger here (repeatedly);
    # this has been moved to #connection so that it happens only once.
    #
    # @see OmniAuth::Strategies::Bookshare#request_phase
    #
    def request(verb, url, opts = {})
      __debug_args((dbg = "OAUTH2 #{__method__}"), binding)
      body = opts[:body]
      body = opts[:body] = url_query(body) if body.is_a?(Hash)
      hdrs = opts[:headers]
      prms = opts[:params]
      url  = connection.build_url(url).to_s

      response =
        connection.run_request(verb, url, body, hdrs) do |req|
          req.params.update(prms) if prms.present?
          __debug_line(dbg) { [verb.to_s.upcase, url, req.params] }
          yield(req) if block_given?
        end
      __debug_line(dbg) { ['RESPONSE', response] }
      response = Response.new(response, parse: opts.slice(:parse))

      case response.status

        when 301, 302, 303, 307
          # Redirect, or keep this response if beyond the limit of redirects.
          __debug_line(dbg) { "REDIRECT #{response.status}" }
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
          __debug_line(dbg) { "REDIRECT #{response.status}" }

        when 400..599
          # Server error.
          __debug_line(dbg) { "ERROR #{response.status}" }
          error = Error.new(response)
          raise(error) if opts[:raise_errors] || options[:raise_errors]
          response.error = error

        else
          # Other error.
          __debug_line(dbg) { "UNEXPECTED #{response.status}" }
          error = Error.new(response)
          raise(error, "Unhandled status code value of #{response.status}")

      end
      response
    end

    # Initializes an AccessToken by making a request to the token endpoint.
    #
    # @param [Hash]  params               For the token endpoint.
    # @param [Hash]  access_token_opts    Passed to the AccessToken object.
    # @param [Class] access_token_class   Class of access token for easier
    #                                       subclassing of OAuth2::AccessToken.
    #
    # @return [AccessToken]               The initialized AccessToken.
    #
    # This method overrides:
    # @see OAuth2::Client#get_token
    #
    def get_token(params, access_token_opts = {}, access_token_class = AccessToken)
      __debug_args((dbg = "OAUTH2 #{__method__}"), binding)
      super.tap do |result|
        __debug { "#{dbg} => #{result.inspect}" }
      end
    end

    # The Authorization Code strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.1
    #
    # This method overrides:
    # @see OAuth2::Client#auth_code
    #
    def auth_code
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The Implicit strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-26#section-4.2
    #
    # This method overrides:
    # @see OAuth2::Client#implicit
    #
    def implicit
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The Resource Owner Password Credentials strategy
    #
    # @return [OAuth2::Strategy::Password]
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.3
    #
    # This method overrides:
    # @see OAuth2::Client#password
    #
    def password
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The Client Credentials strategy
    #
    # @return [OAuth2::Strategy::ClientCredentials]
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.4
    #
    # This method overrides:
    # @see OAuth2::Client#client_credentials
    #
    def client_credentials
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The Client Assertion Strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-10#section-4.1.3
    #
    # This method overrides:
    # @see OAuth2::Client#assertion
    #
    def assertion
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The redirect_uri parameters dynamically assigned in
    # OmniAuth::Strategies::Bookshare#client.
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see OAuth2::Client#redirection_params
    #
    def redirection_params
      options.slice(:redirect_uri).stringify_keys
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::Client => OAuth2::ClientExt

__loading_end(__FILE__)
