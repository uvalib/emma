# app/models/api_reading_list_titles_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiReadingListTitlesList
#
# @attr [Array<AllowsType>]            allows
# @attr [Integer]                      limit
# @attr [Array<Api::Link>]             links
# @attr [String]                       next
# @attr [String]                       readingListId
# @attr [Array<Api::ReadingListTitle>] titles
# @attr [Integer]                      totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_titles_list
#
class ApiReadingListTitlesList < Api::Message

  include Api::Common::LinkMethods
  include Api::Common::ReadingListMethods

  schema do
    has_many  :allows,        AllowsType
    attribute :limit,         Integer
    has_many  :links,         Api::Link
    attribute :next,          String
    attribute :readingListId, String
    has_many  :titles,        Api::ReadingListTitle
    attribute :totalResults,  Integer
  end

end

__loading_end(__FILE__)
