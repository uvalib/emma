# app/records/bs/message/popular_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::PopularList
#
# @attr [String]                                  description
# @attr [String]                                  id
# @attr [Integer]                                 limit
# @attr [Array<Bs::Record::Link>]                 links
# @attr [String]                                  next
# @attr [Array<Bs::Record::TitleMetadataSummary>] popularTitles
# @attr [Integer]                                 totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_popular_list
#
class Bs::Message::PopularList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::TitleMetadataSummary

  schema do
    has_one   :description
    has_one   :id
    has_one   :limit,         Integer
    has_many  :links,         Bs::Record::Link
    has_one   :next
    has_many  :popularTitles, LIST_ELEMENT
    has_one   :totalResults,  Integer
  end

end

__loading_end(__FILE__)
