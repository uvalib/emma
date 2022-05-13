# app/records/lookup/crossref/record/work_free_to_read.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkFreeToRead
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkFreeToRead
#
class Lookup::Crossref::Record::WorkFreeToRead < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :start_date, Lookup::Crossref::Record::DateParts
    has_one :end_date,   Lookup::Crossref::Record::DateParts
  end

end

__loading_end(__FILE__)
