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

  include Bs::Shared::LinkMethods

  schema do
    has_many  :categories,   Bs::Record::CategorySummary
    attribute :limit,        Integer
    has_many  :links,        Bs::Record::Link
    attribute :next,         String
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
