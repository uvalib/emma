# app/records/bs/message/oauth_token.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::OauthTokenError
#
# @attr [TokenErrorType] error
# @attr [String]         error_description
#
# @see https://apidocs.bookshare.org/auth/index.html#_token_error
#
class Bs::Message::OauthTokenError < Bs::Api::Message

  schema do
    attribute :error,             TokenErrorType
    attribute :error_description, String
  end

end

__loading_end(__FILE__)