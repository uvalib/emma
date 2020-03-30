# lib/ext/oauth2/lib/oauth2/client.rb
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

=begin
    # The required query parameters for the authorize URL
    #
    # @param [Hash] params additional query parameters
    def authorize_params(params = {})
      params.merge('response_type' => 'code', 'client_id' => @client.id)
    end
=end

=begin
    # The authorization URL endpoint of the provider
    #
    # @param [Hash] params additional query parameters for the URL
    def authorize_url(params = {})
      @client.authorize_url(authorize_params.merge(params))
    end
=end

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

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::Strategy::AuthCode => OAuth2::Strategy::AuthCodeExt

__loading_end(__FILE__)
