# app/records/bs/message/recommended_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::RecommendedTitles
#
# @attr [Integer]                                 limit
# @attr [Array<Bs::Record::Link>]                 links
# @attr [String]                                  next
# @attr [Array<Bs::Record::TitleMetadataSummary>] recommendedTitles
# @attr [Integer]                                 totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_recommended_titles
#
class Bs::Message::RecommendedTitles < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::TitleMetadataSummary

  schema do
    has_one   :limit,             Integer
    has_many  :links,             Bs::Record::Link
    has_one   :next
    has_many  :recommendedTitles, LIST_ELEMENT
    has_one   :totalResults,      Integer
  end

end

__loading_end(__FILE__)
