# app/records/bs/message/reading_list_titles_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ReadingListTitlesList
#
# @attr [Array<BsAllowsType>]                 allows
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

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::ReadingListMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::ReadingListTitle

  schema do
    has_many  :allows,        BsAllowsType
    has_one   :limit,         Integer
    has_many  :links,         Bs::Record::Link
    has_one   :next
    has_one   :readingListId
    has_many  :titles,        LIST_ELEMENT
    has_one   :totalResults,  Integer
  end

end

__loading_end(__FILE__)
