# app/records/lookup/crossref/record/coverage_full.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::CoverageFull
#
# @see https://api.crossref.org/swagger-ui/index.html#model-CoverageFull
#
class Lookup::Crossref::Record::CoverageFull < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  # noinspection DuplicatedCode
  schema do
    has_one :abstracts_backfile,            Float
    has_one :abstracts_current,             Float
    has_one :affiliations_backfile,         Float
    has_one :affiliations_current,          Float
    has_one :award_numbers_backfile,        Float
    has_one :award_numbers_current,         Float
    has_one :descriptions_backfile,         Float
    has_one :descriptions_current,          Float
    has_one :funders_backfile,              Float
    has_one :funders_current,               Float
    has_one :licenses_backfile,             Float
    has_one :licenses_current,              Float
    has_one :open_references_backfile,      Float
    has_one :open_references_current,       Float
    has_one :orcids_backfile,               Float
    has_one :orcids_current,                Float
    has_one :references_backfile,           Float
    has_one :references_current,            Float
    has_one :resource_links_backfile,       Float
    has_one :resource_links_current,        Float
    has_one :ror_ids_backfile,              Float
    has_one :ror_ids_current,               Float
    has_one :similarity_checking_backfile,  Float
    has_one :similarity_checking_current,   Float
    has_one :update_policies_backfile,      Float
    has_one :update_policies_current,       Float
  end

end

__loading_end(__FILE__)
