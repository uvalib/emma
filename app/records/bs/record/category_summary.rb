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
    has_one   :description
    has_many  :links,       Bs::Record::Link
    has_one   :name
    has_one   :titleCount,  Integer
  end

end

__loading_end(__FILE__)
