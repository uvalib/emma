# app/records/bs/message/user_account_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserAccountList
#
# @attr [Array<AllowsType>]              allows
# @attr [Array<Bs::Record::Link>]        links
# @attr [Integer]                        totalResults
# @attr [Array<Bs::Record::UserAccount>] userAccounts
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_account_list
#
# NOTE: If this is a sequence then why no :next member?
#
class Bs::Message::UserAccountList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,       AllowsType
    has_many  :links,        Bs::Record::Link
    has_one   :totalResults, Integer
    has_many  :userAccounts, Bs::Record::UserAccount
  end

end

__loading_end(__FILE__)
