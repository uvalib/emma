# app/records/lookup/crossref/record/work_journal_issue.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkJournalIssue
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkJournalIssue
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Record::WorkJournalIssue < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :issue
  end

end

__loading_end(__FILE__)
