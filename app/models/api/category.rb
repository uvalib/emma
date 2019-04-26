# app/models/api/category.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/link'

# Api::Category
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_category
#
class Api::Category < Api::Record::Base

  schema do
    attribute :categoryType, CategoryType
    attribute :description,  String
    has_many  :links,        Link
    attribute :name,         String
  end

end

__loading_end(__FILE__)
