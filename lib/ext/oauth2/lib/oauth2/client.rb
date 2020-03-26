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
  module ClientExt

    include Emma::Common
    include Emma::Debug

    OAUTH_DEBUG = true?(ENV['OAUTH_DEBUG'])

=begin
    attr_reader :id, :secret, :site
    attr_accessor :options
    attr_writer :connection
=end

    # Instantiate a new OAuth 2.0 client using the
    # Client ID and Client Secret registered to your
    # application.
    #
    # @param [String] client_id the client_id value
    # @param [String] client_secret the client_secret value
    # @param [Hash] opts the options to create the client with
    # @option opts [String] :site the OAuth2 provider site host
    # @option opts [String] :redirect_uri the absolute URI to the Redirection Endpoint for use in authorization grants and token exchange
    # @option opts [String] :authorize_url ('/oauth/authorize') absolute or relative URL path to the Authorization endpoint
    # @option opts [String] :token_url ('/oauth/token') absolute or relative URL path to the Token endpoint
    # @option opts [Symbol] :token_method (:post) HTTP method to use to request token (:get or :post)
    # @option opts [Symbol] :auth_scheme (:basic_auth) HTTP method to use to authorize request (:basic_auth or :request_body)
    # @option opts [Hash] :connection_opts ({}) Hash of connection options to pass to initialize Faraday with
    # @option opts [FixNum] :max_redirects (5) maximum number of redirects to follow
    # @option opts [Boolean] :raise_errors (true) whether or not to raise an OAuth2::Error
    #  on responses with 400+ status codes
    # @yield [builder] The Faraday connection builder
    def initialize(client_id, client_secret, options = {}, &block)
      __debug_args("OAUTH2 #{__method__}", binding)
      super
=begin
      opts = options.dup
      @id = client_id
      @secret = client_secret
      @site = opts.delete(:site)
      ssl = opts.delete(:ssl)
      @options = {:authorize_url    => '/oauth/authorize',
                  :token_url        => '/oauth/token',
                  :token_method     => :post,
                  :auth_scheme      => :request_body,
                  :connection_opts  => {},
                  :connection_build => block,
                  :max_redirects    => 5,
                  :raise_errors     => true}.merge(opts)
      @options[:connection_opts][:ssl] = ssl if ssl
=end
    end

=begin
    # Set the site host
    #
    # @param [String] the OAuth2 provider site host
    def site=(value)
      @connection = nil
      @site = value
    end
=end

    # The Faraday connection object.
    #
    # @return [Faraday::Connection]
    #
    # == Implementation Notes
    # This corrects the logic error of setting :logger repeatedly in #request
    # by setting it once here.
    #
    def connection
      @connection ||=
        Faraday.new(site, options[:connection_opts]) do |bld|
          bld.response :logger, Log.logger if OAUTH_DEBUG
          if options[:connection_build]
            options[:connection_build].call(bld)
          else
            bld.adapter Faraday.default_adapter
          end
        end
    end

    # The authorize endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    def authorize_url(params = {})
=begin
      params = (params || {}).merge(redirection_params)
      connection.build_url(options[:authorize_url], params).to_s
=end
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The token endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    def token_url(params = nil)
=begin
      connection.build_url(options[:token_url], params).to_s
=end
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # Makes a request relative to the specified site root.
    #
    # @yield [req] Gives access to the request before it is transmitted.
    # @yieldparam [Faraday::Request] req  The Faraday request.
    # @yieldreturn [void]                 The block should access *req*.
    #
    # @param [Symbol] verb            One of :get, :post, :put, :delete.
    # @param [String] url             URL path of request.
    # @param [Hash]   opts            The options to make the request with.
    #
    # @option opts [Hash]         :params   additional query parameters for the URL of the request
    # @option opts [Hash, String] :body     the body of the request
    # @option opts [Hash]         :headers  http request headers
    # @option opts [Boolean] :raise_errors  whether or not to raise an OAuth2::Error on 400+ status
    #   code response for this request.  Will default to client option
    # @option opts [Symbol]       :parse    @see Response#initialize
    #
    # @return [OAuth2::Response]
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
    def request(verb, url, opts = {}, &block)
      __debug_args((dbg = "OAUTH2 #{__method__}"), binding)
      body  = opts[:body]
      body  = opts[:body] = url_query(body) if body.is_a?(Hash)
      hdrs  = opts[:headers]
      parse = opts[:parse] ||= :automatic

      url = connection.build_url(url, opts[:params]).to_s # TODO: keep?
      #url = connection.build_url(url).to_s # TODO: remove?
=begin
      response =
        connection.run_request(verb, url, opts[:body], opts[:headers]) do |req|
          #req.params.update(opts[:params]) if opts[:params] # TODO: remove?
          yield(req) if block_given?
        end
=end
      response = connection.run_request(verb, url, body, hdrs, &block)
      __debug_line(dbg, 'RESPONSE', response) do
        { status: response&.status, body: response&.body }
      end
      response = Response.new(response, parse: parse)

      case response.status

        when 301, 302, 303, 307
          # Redirect, or keep this response if beyond the limit of redirects.
          __debug_line(dbg, "REDIRECT #{response.status}")
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
          __debug_line(dbg, "STATUS #{response.status}")

        when 400..599
          # Server error.
          __debug_line(dbg, "ERROR #{response.status}")
          error = Error.new(response)
          raise(error) if opts[:raise_errors] || options[:raise_errors]
          response.error = error

        else
          # Other error.
          __debug_line(dbg, "UNEXPECTED #{response.status}")
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
    def get_token(params, access_token_opts = {}, access_token_class = AccessToken) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      __debug_args((dbg = "OAUTH2 #{__method__}"), binding)
      access_token_opts['client_id'] ||= id
      super(params, access_token_opts, access_token_class).tap do |result|
        __debug { "#{dbg} => #{result.inspect}" }
      end
=begin
      method = options[:token_method]
      mode   = options[:auth_scheme]
      params = OAuth2::Authenticator.new(id, secret, mode).apply(params)
      opts = {
        raise_errors: options[:raise_errors],
        parse:        (params.delete(:parse) || :automatic),
        headers:      (params.delete(:headers)&.dup || {})
      }
      if method == :post
        opts[:body] = params
        opts[:headers]['Content-Type'] = 'application/x-www-form-urlencoded'
      else
        opts[:params] = params
      end
      response = request(method, token_url, opts)
      content  = response&.parsed || {}
      if options[:raise_errors] && !content['access_token']
        error = Error.new(response)
        raise(error)
      end
      access_token_class.from_hash(self, content.merge(access_token_opts))
=end
    end

    # The Authorization Code strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.1
    def auth_code
=begin
      @auth_code ||= OAuth2::Strategy::AuthCode.new(self)
=end
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The Implicit strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-26#section-4.2
    def implicit
=begin
      @implicit ||= OAuth2::Strategy::Implicit.new(self)
=end
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The Resource Owner Password Credentials strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.3
    def password
=begin
      @password ||= OAuth2::Strategy::Password.new(self)
=end
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The Client Credentials strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.4
    def client_credentials
=begin
      @client_credentials ||= OAuth2::Strategy::ClientCredentials.new(self)
=end
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    def assertion
=begin
      @assertion ||= OAuth2::Strategy::Assertion.new(self)
=end
      super.tap do |result|
        __debug { "OAUTH2 #{__method__} => #{result.inspect}" }
      end
    end

    # The redirect_uri parameters, if configured
    #
    # The redirect_uri query parameter is OPTIONAL (though encouraged) when
    # requesting authorization. If it is provided at authorization time it MUST
    # also be provided with the token exchange request.
    #
    # Providing the :redirect_uri to the OAuth2::Client instantiation will take
    # care of managing this.
    #
    # @api semipublic
    #
    # @see https://tools.ietf.org/html/rfc6749#section-4.1
    # @see https://tools.ietf.org/html/rfc6749#section-4.1.3
    # @see https://tools.ietf.org/html/rfc6749#section-4.2.1
    # @see https://tools.ietf.org/html/rfc6749#section-10.6
    #
    # @return [Hash] the params to add to a request or URL
    #
    def redirection_params
      #options.slice(:redirect_uri).map { |k, v| [k.to_s, url_escape(v)] }.to_h
      options.slice(:redirect_uri).map { |k, v| [k.to_s, v] }.to_h
=begin
      if options[:redirect_uri]
        {'redirect_uri' => options[:redirect_uri]}
      else
        {}
      end
=end
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::Client => OAuth2::ClientExt

__loading_end(__FILE__)
