# app/records/lookup/crossref/record/list_works.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bulk work results.
#
class Lookup::Crossref::Record::ListWorks < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CollectionMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Lookup::Crossref::Record::Work

  schema do
    has_many :items,          LIST_ELEMENT
    has_one  :items_per_page, Integer
    has_one  :next_cursor
    has_one  :query,          Lookup::Crossref::Record::Query
    has_one  :total_results,  Integer
  end

end

__loading_end(__FILE__)
