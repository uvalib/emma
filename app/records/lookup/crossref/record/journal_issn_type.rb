# app/records/lookup/crossref/record/journal_issn_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::JournalIssnType
#
# @see https://api.crossref.org/swagger-ui/index.html#model-JournalIssnType
#
class Lookup::Crossref::Record::JournalIssnType < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :type
    has_one :value
  end

end

__loading_end(__FILE__)
