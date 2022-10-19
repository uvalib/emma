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
  # @!attribute [r] client
  #   @return [OAuth2::Client]
  #
  # @!attribute [r] token
  #   @return [String]
  #
  # @!attribute [r] expires_in
  #   @return [Integer, nil]
  #
  # @!attribute [r] expires_at
  #   @return [Integer, nil]
  #
  # @!attribute [r] params
  #
  # @!attribute [rw] options
  #   @return [Hash]
  #
  # @!attribute [rw] refresh_token
  #   @return [String, nil]
  #
  module AccessTokenExt

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
    # @see OAuth2::AccessToken#configure_authentication!
    #
    def configure_authentication!(opts)
      opts[:params] ||= {}
      opts[:params][:api_key] = @client.id
      super
    end

  end

  if DEBUG_OAUTH

    # Overrides adding extra debugging around method calls.
    #
    module AccessTokenDebug

      include OAuth2::ExtensionDebugging

      # =======================================================================
      # :section: OAuth2::AccessToken overrides
      # =======================================================================

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
      #                                               which the token will
      #                                               expire.
      #
      # @option opts [FixNum,String] :expires_at      The epoch time in seconds
      #                                               which the token will
      #                                               expire.
      #
      # @option opts [Symbol]        :mode            The transmission mode of
      #                                               Access Token parameter
      #                                               value: :query, :body, or
      #                                               :header (default).
      #
      # @option opts [String]        :header_format   Format of Authorization
      #                                               header. Def: 'Bearer %s'.
      #
      # @option opts [String]        :param_name      The parameter name to use
      #                                               for transmission of the
      #                                               Access Token value in
      #                                               :body or :query
      #                                               transmission mode.
      #                                               Default: 'access_token'.
      #
      def initialize(client, token, opts = {})
        super
        __ext_debug(binding) do
          { '@expires_in': @expires_in, '@options': @options }
        end
      end

      # Refreshes the current Access Token.
      #
      # @param [Hash] params            Additional token parameters.
      #
      # @return [AccessToken]           A new AccessToken instance.
      #
      # @note options should be carried over to the new AccessToken
      #
      def refresh!(params = {})
        super
          .tap { |result| __ext_debug("--> #{result.inspect}") }
      end

      # Make a request using the Access Token.
      #
      # @param [Symbol] verb            The HTTP request method.
      # @param [String] path            The URL of the request.
      # @param [Hash]   opts            Passed to OAuth2::Client#request.
      # @param [Proc]   block           Passed to OAuth2::Client#request.
      #
      # @return [OAuth2::Response]
      #
      def request(verb, path, opts = {}, &block)
        __ext_debug(binding)
        super
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::AccessToken => OAuth2::AccessTokenExt
override OAuth2::AccessToken => OAuth2::AccessTokenDebug if DEBUG_OAUTH

__loading_end(__FILE__)
