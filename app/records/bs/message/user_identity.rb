# app/records/bs/message/user_identity.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserIdentity
#
# @attr [Array<Bs::Record::Link>] links
# @attr [Bs::Record::Name]        name
# @attr [String]                  username
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_identity
#
class Bs::Message::UserIdentity < Bs::Api::Message

  include Bs::Shared::AccountMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many  :links,    Bs::Record::Link
    has_one   :name,     Bs::Record::Name
    has_one   :username
  end

end

__loading_end(__FILE__)
