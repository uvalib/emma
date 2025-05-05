# app/records/lookup/crossref/record/journals_message_message_items_coverage_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::JournalsMessageMessageItemsCoverageType
#
# @see https://api.crossref.org/swagger-ui/index.html#model-JournalsMessageMessageItemsCoverageType
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Record::JournalsMessageMessageItemsCoverageType < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :all,       Lookup::Crossref::Record::Coverage
    has_one :backfile,  Lookup::Crossref::Record::Coverage
    has_one :current,   Lookup::Crossref::Record::Coverage
  end

end

__loading_end(__FILE__)
