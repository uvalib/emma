# app/models/api_active_periodical_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiActivePeriodicalList
#
# @attr [Array<Api::ActivePeriodical>] activeTitles
# @attr [Array<AllowsType>]            allows
# @attr [Integer]                      limit
# @attr [Array<Api::Link>]             links
# @attr [Api::StatusModel]             message
# @attr [String]                       next
# @attr [Integer]                      totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_periodical_list
#
# NOTE: This duplicates the form of:
# @see ApiActiveBookList
#
class ApiActivePeriodicalList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :activeTitles, Api::ActivePeriodical
    has_many  :allows,       AllowsType
    attribute :limit,        Integer
    has_many  :links,        Api::Link
    has_one   :message,      Api::StatusModel
    attribute :next,         String
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
