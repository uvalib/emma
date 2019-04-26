# app/models/api/category_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/link'

# Api::CategorySummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_category_summary
#
class Api::CategorySummary < Api::Record::Base

  schema do
    attribute :description, String
    has_many  :links,       Link
    attribute :name,        String
    attribute :titleCount,  Integer
  end

end

__loading_end(__FILE__)
