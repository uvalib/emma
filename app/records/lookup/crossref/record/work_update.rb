# app/records/lookup/crossref/record/work_update.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkUpdate
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkUpdate
#
class Lookup::Crossref::Record::WorkUpdate < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :doi
    has_one :label
    has_one :type
    has_one :updated, Lookup::Crossref::Record::Date
  end

end

__loading_end(__FILE__)
