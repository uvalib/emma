# app/records/bs/message/bookmark_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::BookmarkList
#
# @attr [Array<BsAllowsType>]         allows
# @attr [Array<Bs::Record::Bookmark>] bookmarks
# @attr [Integer]                     limit
# @attr [Array<Bs::Record::Link>]     links
# @attr [String]                      next
# @attr [Integer]                     totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_bookmark_list
#
class Bs::Message::BookmarkList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::Bookmark

  schema do
    has_many  :allows,       BsAllowsType
    has_many  :bookmarks,    LIST_ELEMENT
    has_one   :limit,        Integer
    has_many  :links,        Bs::Record::Link
    has_one   :next
    has_one   :totalResults, Integer
  end

end

__loading_end(__FILE__)
