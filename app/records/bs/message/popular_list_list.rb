# app/records/bs/message/popular_list_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::PopularListList
#
# @attr [Integer]                               limit
# @attr [Array<Bs::Record::Link>]               links
# @attr [String]                                next
# @attr [Array<Bs::Record::PopularListSummary>] popularLists
# @attr [Integer]                               totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_popular_list_list
#
class Bs::Message::PopularListList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :limit,         Integer
    has_many  :links,         Bs::Record::Link
    has_one   :next
    has_many  :popularLists,  Bs::Record::PopularListSummary
    has_one   :totalResults,  Integer
  end

end

__loading_end(__FILE__)
