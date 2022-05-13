# app/records/lookup/crossref/record/work_license.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkLicense
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkLicense
#
class Lookup::Crossref::Record::WorkLicense < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :content_version
    has_one :delay_in_days,   Integer
    has_one :start,           Lookup::Crossref::Record::Date
    has_one :url
  end

end

__loading_end(__FILE__)
