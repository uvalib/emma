# app/records/bs/message/categories_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::CategoriesList
#
# @attr [Array<Bs::Record::CategorySummary>] categories
# @attr [Integer]                            limit
# @attr [Array<Bs::Record::Link>]            links
# @attr [String]                             next
# @attr [Integer]                            totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_categories_list
#
class Bs::Message::CategoriesList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::CategorySummary

  schema do
    has_many  :categories,   LIST_ELEMENT
    has_one   :limit,        Integer
    has_many  :links,        Bs::Record::Link
    has_one   :next
    has_one   :totalResults, Integer
  end

end

__loading_end(__FILE__)
