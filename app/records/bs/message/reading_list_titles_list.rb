# app/records/bs/message/reading_list_titles_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ReadingListTitlesList
#
# @attr [Array<AllowsType>]                   allows
# @attr [Integer]                             limit
# @attr [Array<Bs::Record::Link>]             links
# @attr [String]                              next
# @attr [String]                              readingListId
# @attr [Array<Bs::Record::ReadingListTitle>] titles
# @attr [Integer]                             totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_titles_list
#
class Bs::Message::ReadingListTitlesList < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::ReadingListMethods

  schema do
    has_many  :allows,        AllowsType
    attribute :limit,         Integer
    has_many  :links,         Bs::Record::Link
    attribute :next,          String
    attribute :readingListId, String
    has_many  :titles,        Bs::Record::ReadingListTitle
    attribute :totalResults,  Integer
  end

end

__loading_end(__FILE__)
