# app/models/api_oauth_token.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

# ApiOauthToken
#
# @see https://apidocs-qa.bookshare.org/auth/index.html#_token
#
class ApiOauthToken < Api::Message

  schema do
    attribute :access_token,  String
    attribute :expires_in,    String
    attribute :refresh_token, String
    attribute :scope,         String
    attribute :token_type,    String
  end

end

__loading_end(__FILE__)
