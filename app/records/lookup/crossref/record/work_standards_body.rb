# app/records/lookup/crossref/record/work_standards_body.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkStandardsBody
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkStandardsBody
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Record::WorkStandardsBody < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :acronym
    has_one  :name
  end

end

__loading_end(__FILE__)
