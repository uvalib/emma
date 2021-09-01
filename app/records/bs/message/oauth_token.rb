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

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :access_token
    has_one   :expires_in
    has_one   :refresh_token
    has_one   :scope
    has_one   :token_type
  end

end

__loading_end(__FILE__)
