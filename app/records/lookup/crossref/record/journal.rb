# app/records/lookup/crossref/record/journal.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata record schema for a journal lookup.
#
# @see https://api.crossref.org/swagger-ui/index.html#model-Journal
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Record::Journal < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CreatorMethods
  include Lookup::Crossref::Shared::DateMethods
  include Lookup::Crossref::Shared::IdentifierMethods
  include Lookup::Crossref::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one  :breakdowns,             Lookup::Crossref::Record::JournalsMessageMessageItemsBreakdowns
    has_one  :coverage,               Lookup::Crossref::Record::CoverageFull
    has_one  :coverage_type,          Lookup::Crossref::Record::JournalsMessageMessageItemsCoverageType
    has_one  :flags,                  Lookup::Crossref::Record::Flags
    has_one  :is_referenced_by_count, Lookup::Crossref::Record::DoiCounts
    has_many :issn
    has_one  :issn_type,              Lookup::Crossref::Record::JournalIssnType
    has_one  :last_status_check_time, Integer
    has_one  :publisher
    has_many :subjects
    has_one  :title
  end

end

__loading_end(__FILE__)
