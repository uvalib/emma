# app/records/lookup/crossref/record/affiliation.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::Affiliation
#
# @see https://api.crossref.org/swagger-ui/index.html#model-Affiliation
#
class Lookup::Crossref::Record::Affiliation < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :name
  end

end

__loading_end(__FILE__)
