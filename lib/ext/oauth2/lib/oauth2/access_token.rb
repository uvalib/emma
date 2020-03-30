# lib/ext/oauth2/lib/oauth2/access_token.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the OAuth2 gem.

__loading_begin(__FILE__)

require 'oauth2/access_token'

module OAuth2

  # Override definitions to be prepended to OAuth2::AccessToken.
  #
  # !@attribute [r] client
  #   @return [OAuth2::Client]
  #
  # !@attribute [r] token
  #   @return [String]
  #
  # !@attribute [r] expires_in
  #   @return [Integer, nil]
  #
  # !@attribute [r] expires_at
  #   @return [Integer, nil]
  #
  # !@attribute [r] params
  #
  # !@attribute [rw] options
  #   @return [Hash]
  #
  # !@attribute [rw] refresh_token
  #   @return [String, nil]
  #
  module AccessTokenExt

    include Emma::Debug

    # =========================================================================
    # :section: OAuth2::AccessToken overrides
    # =========================================================================

    public

    # Initialize an AccessToken.
    #
    # @param [Client] client          The OAuth2::Client instance.
    # @param [String] token           The Access Token value.
    # @param [Hash]   opts
    #
    # @option opts [String]        :refresh_token   The refresh_token value.
    #
    # @option opts [FixNum,String] :expires_in      The number of seconds in
    #                                               which the token will expire
    #
    # @option opts [FixNum,String] :expires_at      The epoch time in seconds
    #                                               which the token will expire
    #
    # @option opts [Symbol]        :mode            The transmission mode of
    #                                               the Access Token parameter
    #                                               value: :query, :body, or
    #                                               :header (default).
    #
    # @option opts [String]        :header_format   Format of the Authorization
    #                                               header. Def: 'Bearer %s'.
    #
    # @option opts [String]        :param_name      The parameter name to use
    #                                               for transmission of the
    #                                               Access Token value in :body
    #                                               or :query transmission mode
    #                                               Default: 'access_token'.
    #
    # This method overrides:
    # @see OAuth2::AccessToken#initialize
    #
    def initialize(client, token, opts = {}) # rubocop:disable Metrics/AbcSize
      super
      __debug_args("ACCESS_TOKEN #{__method__}", binding) do
        { '@expires_in': @expires_in, '@options': @options }
      end
    end

=begin
    # Indexer to additional params present in token response
    #
    # @param [String] key entry key to Hash
    def [](key)
      @params[key]
    end
=end

=begin
    # Whether or not the token expires
    #
    # @return [Boolean]
    def expires?
      !!@expires_at
    end
=end

=begin
    # Whether or not the token is expired
    #
    # @return [Boolean]
    def expired?
      expires? && (expires_at < Time.now.to_i)
    end
=end

    # Refreshes the current Access Token.
    #
    # @param [Hash] params            Additional token parameters.
    #
    # @return [AccessToken]           A new AccessToken instance.
    #
    # @note options should be carried over to the new AccessToken
    #
    # This method overrides:
    # @see OAuth2::AccessToken#refresh!
    #
    def refresh!(params = {})
      super.tap do |res|
        __debug { "ACCESS_TOKEN #{__method__} => #{res.inspect}" }
      end
    end

=begin
    # Convert AccessToken to a hash which can be used to rebuild itself with
    # AccessToken.from_hash.
    #
    # @return [Hash]                  A hash of AccessToken property values.
    #
    def to_hash
      params.merge(
        access_token:   token,
        refresh_token:  refresh_token,
        expires_at:     expires_at
      )
    end
=end

    # Make a request using the Access Token.
    #
    # @param [Symbol] verb            The HTTP request method.
    # @param [String] path            The URL of the request.
    # @param [Hash]   opts            Passed to OAuth2::Client#request.
    # @param [Proc]   block           Passed to OAuth2::Client#request.
    #
    # @return [OAuth2::Response]
    #
    # This method overrides:
    # @see OAuth2::AccessToken#request
    #
    def request(verb, path, opts = {}, &block)
      configure_authentication!(opts)
      __debug_args("ACCESS_TOKEN #{__method__}", binding)
      @client.request(verb, path, opts, &block)
    end

=begin
    # Get the headers hash (includes Authorization token).
    #
    # @return [Hash]
    #
    def headers
      { 'Authorization' => (options[:header_format] % token) }
    end
=end

    # =========================================================================
    # :section: OAuth2::AccessToken overrides
    # =========================================================================

    private

    # configure_authentication!
    #
    # @param [Hash] opts
    #
    # @return [void]
    #
    # This method overrides:
    # @see OAuth2::AccessToken#configure_authentication!
    #
    def configure_authentication!(opts)
      opts[:params] ||= {}
      opts[:params][:api_key] = @client.id
      super
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::AccessToken => OAuth2::AccessTokenExt

__loading_end(__FILE__)
