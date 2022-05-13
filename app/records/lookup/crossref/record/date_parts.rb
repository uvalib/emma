# app/records/lookup/crossref/record/date.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata record schema for an item lookup.
#
# @attr [Array<DatePart>] date_parts
# @attr [DateTime]        date_time
# @attr [Integer]         timestamp
#
# @see https://api.crossref.org/swagger-ui/index.html#model-DateParts
#
class Lookup::Crossref::Record::DateParts < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::DateMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :date_parts, Array # TODO: DatePart
  end

end

__loading_end(__FILE__)
