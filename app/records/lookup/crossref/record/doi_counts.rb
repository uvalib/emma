# app/records/lookup/crossref/record/doi_counts.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::DoiCounts
#
# @see https://api.crossref.org/swagger-ui/index.html#model-DoiCounts
#
class Lookup::Crossref::Record::DoiCounts < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :backfile_dois, Integer
    has_one :current_dois,  Integer
    has_one :total_dois,    Integer
  end

end

__loading_end(__FILE__)
