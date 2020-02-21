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

    OAUTH_DEBUG = true?(ENV['OAUTH_DEBUG'])

=begin
    attr_reader :id, :secret, :site
    attr_accessor :options
    attr_writer :connection
=end

=begin
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
    end
=end

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

=begin
    # The authorize endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    def authorize_url(params = {})
      params = (params || {}).merge(redirection_params)
      connection.build_url(options[:authorize_url], params).to_s
    end
=end

=begin
    # The token endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    def token_url(params = nil)
      connection.build_url(options[:token_url], params).to_s
    end
=end

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
    # 1 The original code had a problem in setting :logger here (repeatedly);
    #   this has been moved to #connection so that it happens only once.
    #
    # 2 NOTE: There is currently a problem going directly to authorize_url.
    #   For some reason (probably related to headers), Location is returned
    #   as "https://auth.staging.bookshare.org/user_login", which fails.  The
    #   redirection response code rewrites the location to remove the
    #   ".staging" part of the URL since
    #   "https://auth.bookshare.org/user_login" appears to work correctly.
    #
    # @see OmniAuth::Strategies::Bookshare#request_phase
    #
    def request(verb, url, opts = nil)
      opts ||= {}
      $stderr.puts "OAUTH2 #{__method__} | #{verb} #{url} | opts = #{opts.inspect}"

      url = connection.build_url(url, opts[:params]).to_s
      parse = opts[:parse] || :automatic
      response =
        connection.run_request(verb, url, opts[:body], opts[:headers]) do |req|
          yield(req) if block_given?
        end
      response = Response.new(response, parse: parse)

      case response.status

        when 301, 302, 303, 307
          # Redirect, or keep this response if beyond the limit of redirects.
          opts[:redirect_count] ||= 0
          opts[:redirect_count] += 1
          if (max = options[:max_redirects]) && (opts[:redirect_count] <= max)
            if response.status == 303
              verb = :get
              opts.delete(:body)
            end
            url = response.headers['Location'].to_s
            # NOTE: temporarily(?) fixing Bookshare redirect problem...
            url = url.sub(%r{(/auth\.)staging\.}, '\1')
            response = request(verb, url, opts)
          end

        when 200..299, 300..399
          # On non-redirecting 3xx statuses, just return the response.

        when 400..599
          # Server error.
          error = Error.new(response)
          raise(error) if opts.fetch(:raise_errors, options[:raise_errors])
          response.error = error

        else
          # Other error.
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
      $stderr.puts "OAUTH2 #{__method__} | access_token_opts = #{access_token_opts.inspect} | access_token_class = #{access_token_class.inspect}"
      super
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
      @auth_code ||= OAuth2::Strategy::AuthCode.new(self).tap { |result|
        $stderr.puts "OAUTH2 #{__method__} => #{result.inspect}"
      }
    end

=begin
    # The Implicit strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-26#section-4.2
    def implicit
      @implicit ||= OAuth2::Strategy::Implicit.new(self)
    end
=end

=begin
    # The Resource Owner Password Credentials strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.3
    def password
      @password ||= OAuth2::Strategy::Password.new(self)
    end
=end

=begin
    # The Client Credentials strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.4
    def client_credentials
      @client_credentials ||= OAuth2::Strategy::ClientCredentials.new(self)
    end
=end

=begin
    def assertion
      @assertion ||= OAuth2::Strategy::Assertion.new(self)
    end
=end

=begin
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
    # @return [Hash] the params to add to a request or URL
    def redirection_params
      if options[:redirect_uri]
        {'redirect_uri' => options[:redirect_uri]}
      else
        {}
      end
    end
=end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::Client => OAuth2::ClientExt

__loading_end(__FILE__)
