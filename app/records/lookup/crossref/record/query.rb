# app/records/lookup/crossref/record/query.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::Query
#
# @see https://api.crossref.org/swagger-ui/index.html#model-Query
#
class Lookup::Crossref::Record::Query < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :search_terms
    has_one :start_index
  end

end

__loading_end(__FILE__)
