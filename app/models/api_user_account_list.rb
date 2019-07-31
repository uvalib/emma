# app/models/api_user_account_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/user_account'

# ApiUserAccountList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_account_list
#
# TODO: If this is a sequence then why no :next member?
#
class ApiUserAccountList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,       AllowsType
    has_many  :links,        Api::Link
    attribute :totalResults, Integer
    has_many  :userAccounts, Api::UserAccount
  end

end

__loading_end(__FILE__)
