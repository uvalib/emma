# app/models/api_active_book_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/active_book'
require_relative 'api/status_model'

# ApiActiveBookList
#
# @attr [Array<Api::ActiveBook>] activeTitles
# @attr [Array<AllowsType>]      allows
# @attr [Integer]                limit
# @attr [Array<Api::Link>]       links
# @attr [Api::StatusModel]       message
# @attr [String]                 next
# @attr [Integer]                totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_book_list
#
# NOTE: This duplicates the form of:
# @see ApiActivePeriodicalList
#
class ApiActiveBookList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :activeTitles, Api::ActiveBook
    has_many  :allows,       AllowsType
    attribute :limit,        Integer
    has_many  :links,        Api::Link
    has_one   :message,      Api::StatusModel
    attribute :next,         String
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
