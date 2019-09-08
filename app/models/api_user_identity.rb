# app/models/api_user_identity.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiUserIdentity
#
# @attr [Array<Api::Link>] links
# @attr [Api::Name]        name
# @attr [String]           username
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_identity
#
class ApiUserIdentity < Api::Message

  include Api::Common::AccountMethods
  include Api::Common::LinkMethods

  schema do
    has_many  :links,    Api::Link
    has_one   :name,     Api::Name
    attribute :username, String
  end

end

__loading_end(__FILE__)
