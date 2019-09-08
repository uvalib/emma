# app/models/api_reading_list_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiReadingListList
#
# @attr [Array<AllowsType>]               allows
# @attr [Integer]                         limit
# @attr [Array<Api::Link>]                links
# @attr [Array<Api::ReadingListUserView>] lists
# @attr [String]                          next
# @attr [Integer]                         totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_list
#
class ApiReadingListList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,        AllowsType
    attribute :limit,         Integer
    has_many  :links,         Api::Link
    has_many  :lists,         Api::ReadingListUserView
    attribute :next,          String
    attribute :totalResults,  Integer
  end

end

__loading_end(__FILE__)
