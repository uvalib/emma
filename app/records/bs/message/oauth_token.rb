# app/records/bs/message/oauth_token.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::OauthToken
#
# @attr [String] access_token
# @attr [String] expires_in
# @attr [String] refresh_token
# @attr [String] scope
# @attr [String] token_type
#
# @see https://apidocs.bookshare.org/auth/index.html#_token
#
class Bs::Message::OauthToken < Bs::Api::Message

  schema do
    attribute :access_token,  String
    attribute :expires_in,    String
    attribute :refresh_token, String
    attribute :scope,         String
    attribute :token_type,    String
  end

end

__loading_end(__FILE__)
