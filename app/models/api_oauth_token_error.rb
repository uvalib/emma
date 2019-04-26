# app/models/api_oauth_token.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

# ApiOauthTokenError
#
# @see https://apidocs-qa.bookshare.org/auth/index.html#_token_error
#
class ApiOauthTokenError < Api::Message

  schema do
    attribute :error,             TokenErrorType
    attribute :error_description, String
  end

end

__loading_end(__FILE__)
