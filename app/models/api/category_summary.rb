# app/models/api/category_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'link'
require_relative 'common/category_methods'
require_relative 'common/link_methods'

# Api::CategorySummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_category_summary
#
class Api::CategorySummary < Api::Record::Base

  schema do
    attribute :description, String
    has_many  :links,       Api::Link
    attribute :name,        String
    attribute :titleCount,  Integer
  end

  include Api::Common::CategoryMethods
  include Api::Common::LinkMethods

end

__loading_end(__FILE__)
