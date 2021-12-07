# app/records/bs/message/user_account_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserAccountList
#
# @attr [Array<BsAllowsType>]            allows
# @attr [Array<Bs::Record::Link>]        links
# @attr [String]                         next
# @attr [Integer]                        totalResults
# @attr [Array<Bs::Record::UserAccount>] userAccounts
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_account_list
#
class Bs::Message::UserAccountList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::UserAccount

  schema do
    has_many  :allows,       BsAllowsType
    has_many  :links,        Bs::Record::Link
    has_one   :next
    has_one   :totalResults, Integer
    has_many  :userAccounts, LIST_ELEMENT
  end

end

__loading_end(__FILE__)
