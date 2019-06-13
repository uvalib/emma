# app/models/api_user_identity.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/link'
require_relative 'api/name'

# ApiUserIdentity
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_identity
#
class ApiUserIdentity < Api::Message

  schema do
    has_many  :links,    Api::Link
    has_one   :name,     Api::Name
    attribute :username, String
  end

end

__loading_end(__FILE__)
