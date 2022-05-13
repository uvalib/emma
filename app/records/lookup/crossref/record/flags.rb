# app/records/lookup/crossref/record/flags.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::Flags
#
# @see https://api.crossref.org/swagger-ui/index.html#model-Flags
#
class Lookup::Crossref::Record::Flags < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  # noinspection DuplicatedCode
  schema do
    has_one :deposits,                          Boolean
    has_one :deposits_abstracts_backfile,       Boolean
    has_one :deposits_abstracts_current,        Boolean
    has_one :deposits_affiliations_backfile,    Boolean
    has_one :deposits_affiliations_current,     Boolean
    has_one :deposits_articles,                 Boolean
    has_one :deposits_award_numbers_backfile,   Boolean
    has_one :deposits_award_numbers_current,    Boolean
    has_one :deposits_descriptions_backfile,    Boolean
    has_one :deposits_descriptions_current,     Boolean
    has_one :deposits_funders_backfile,         Boolean
    has_one :deposits_funders_current,          Boolean
    has_one :deposits_licenses_backfile,        Boolean
    has_one :deposits_licenses_current,         Boolean
    has_one :deposits_orcids_backfile,          Boolean
    has_one :deposits_orcids_current,           Boolean
    has_one :deposits_references_backfile,      Boolean
    has_one :deposits_references_current,       Boolean
    has_one :deposits_resource_links_backfile,  Boolean
    has_one :deposits_resource_links_current,   Boolean
    has_one :deposits_ror_ids_backfile,         Boolean
    has_one :deposits_ror_ids_current,          Boolean
    has_one :deposits_update_policies_backfile, Boolean
    has_one :deposits_update_policies_current,  Boolean
  end

end

__loading_end(__FILE__)
