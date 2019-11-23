# app/records/bs/record/category_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::CategorySummary
#
# @attr [String]                  description
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  name
# @attr [Integer]                 titleCount
#
# @see https://apidocs.bookshare.org/reference/index.html#_category_summary
#
class Bs::Record::CategorySummary < Bs::Api::Record

  include Bs::Shared::CategoryMethods
  include Bs::Shared::LinkMethods

  schema do
    attribute :description, String
    has_many  :links,       Bs::Record::Link
    attribute :name,        String
    attribute :titleCount,  Integer
  end

end

__loading_end(__FILE__)
