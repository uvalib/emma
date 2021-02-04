# lib/ext/oauth2/lib/oauth2/strategy/auth_code.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the OAuth2 gem.

__loading_begin(__FILE__)

require 'oauth2/client'

module OAuth2

  # Override definitions to be prepended to OAuth2::Strategy::AuthCode.
  #
  module Strategy::AuthCodeExt

    # =========================================================================
    # :section: OAuth2::Strategy::AuthCode overrides
    # =========================================================================

    public

    # Retrieve an access token given the specified validation code.
    #
    # @param [String] code            The Authorization Code value.
    # @param [Hash]   params          Additional parameters.
    # @param [Hash]   opts
    #
    # This method overrides:
    # @see OAuth2::Strategy::AuthCode#get_token
    #
    def get_token(code, params = {}, opts = {})
      token_params = {
        grant_type: 'authorization_code',
        code:       code,
        client_id:  @client.id,
      }
      token_params.merge!(@client.redirection_params)
      token_params.merge!(params)
      token_params.stringify_keys!
      @client.get_token(token_params, opts)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The required query parameters for the revoke URL
    #
    # @param [Hash, nil] params       Additional query parameters.
    #
    # @return [Hash]
    #
    def revoke_params(params = nil)
      result = { grant_type: 'authorization_code' }
      # noinspection RubyYardReturnMatch
      params&.symbolize_keys&.merge!(result) || result
    end

    # The token revocation endpoint URL of the OAuth2 provider.
    #
    # @param [OAuth2::AccessToken, Hash, String] token
    # @param [Hash, nil] params       Additional query parameters.
    #
    # @return [String]
    # @return [nil]                   If no token was provided or found.
    #
    def revoke_url(token, params = nil)
      @client.revoke_url(token, revoke_params(params))
    end

    # Indicate to the provider that the token should be invalidated (in order
    # to terminate the session).
    #
    # @param [OAuth2::AccessToken, Hash, String] token
    # @param [Hash, nil] params       Additional query parameters.
    # @param [Hash, nil] opts         Options.
    #
    # @return [OAuth2::Response]
    # @return [nil]                   If no token was provided or found.
    #
    def revoke_token(token, params = nil, opts = nil)
      @client.revoke_token(token, revoke_params(params), opts)
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::Strategy::AuthCode => OAuth2::Strategy::AuthCodeExt

__loading_end(__FILE__)
