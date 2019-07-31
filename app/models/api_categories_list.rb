# app/models/api_categories_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/category_summary'

# ApiCategoriesList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_categories_list
#
class ApiCategoriesList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :categories,   Api::CategorySummary
    attribute :limit,        Integer
    has_many  :links,        Api::Link
    attribute :next,         String
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
