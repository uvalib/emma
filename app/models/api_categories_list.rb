# app/models/api_categories_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/category_summary'
require 'api/link'

# ApiCategoriesList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_categories_list
#
class ApiCategoriesList < Api::Message

  schema do
    has_many  :categories,   CategorySummary
    attribute :limit,        Integer
    has_many  :links,        Link
    attribute :next,         String
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
