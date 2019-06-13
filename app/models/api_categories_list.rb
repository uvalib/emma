# app/models/api_categories_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/category_summary'
require_relative 'api/link'
require_relative 'api/common/sequence_methods'

# ApiCategoriesList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_categories_list
#
class ApiCategoriesList < Api::Message

  schema do
    has_many  :categories,   Api::CategorySummary
    attribute :limit,        Integer
    has_many  :links,        Api::Link
    attribute :next,         String
    attribute :totalResults, Integer
  end

  include Api::Common::SequenceMethods

end

__loading_end(__FILE__)
