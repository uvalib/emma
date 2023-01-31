# app/records/lookup/crossref/record/coverage.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::Coverage
#
# @see https://api.crossref.org/swagger-ui/index.html#model-Coverage
#
class Lookup::Crossref::Record::Coverage < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :abstracts,               Float
    has_one :affiliations,            Float
    has_one :award_numbers,           Float
    has_one :descriptions,            Float
    has_one :funders,                 Float
    has_one :last_status_check_time,  Integer
    has_one :licenses,                Float
    has_one :open_references,         Float
    has_one :orcids,                  Float
    has_one :references,              Float
    has_one :resource_links,          Float
    has_one :ror_ids,                 Float
    has_one :similarity_checking,     Float
    has_one :update_policies,         Float
  end

end

__loading_end(__FILE__)
