# app/models/api/category_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::CategorySummary
#
# @attr [String]           description
# @attr [Array<Api::Link>] links
# @attr [String]           name
# @attr [Integer]          titleCount
#
# @see https://apidocs.bookshare.org/reference/index.html#_category_summary
#
class Api::CategorySummary < Api::Record::Base

  include Api::Common::CategoryMethods
  include Api::Common::LinkMethods

  schema do
    attribute :description, String
    has_many  :links,       Api::Link
    attribute :name,        String
    attribute :titleCount,  Integer
  end

end

__loading_end(__FILE__)
