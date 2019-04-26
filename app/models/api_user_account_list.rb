# app/models/api_user_account_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/user_account'

# ApiUserAccountList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_account_list
#
class ApiUserAccountList < Api::Message

  schema do
    has_many  :allows,       String
    has_many  :links,        Link
    attribute :totalResults, Integer
    has_many  :userAccounts, UserAccount
  end

end

__loading_end(__FILE__)
