# app/records/bs/record/popular_list_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::PopularListSummary
#
# @attr [String]                  description
# @attr [String]                  id
# @attr [Array<Bs::Record::Link>] links
#
# @see https://apidocs.bookshare.org/reference/index.html#_popular_list_summary
#
class Bs::Record::PopularListSummary < Bs::Api::Record

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :description
    has_one   :id
    has_many  :links,       Bs::Record::Link
  end

end

__loading_end(__FILE__)
