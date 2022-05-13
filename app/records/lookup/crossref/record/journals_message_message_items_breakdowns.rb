# app/records/lookup/crossref/record/journals_message_message_items_breakdowns.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::JournalsMessageMessageItemsBreakdowns
#
# @see https://api.crossref.org/swagger-ui/index.html#model-JournalsMessageMessageItemsBreakdowns
#
#--
# noinspection RubyClassModuleNamingConvention, LongLine
#++
class Lookup::Crossref::Record::JournalsMessageMessageItemsBreakdowns < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::DateMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :dois_by_issued_year, Array # TODO: YearTotal
  end

end

__loading_end(__FILE__)
