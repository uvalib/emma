# app/records/lookup/crossref/record/work_domain.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkDomain
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkDomain
#
class Lookup::Crossref::Record::WorkDomain < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one  :crossmark_restriction, Boolean
    has_many :domain
  end

end

__loading_end(__FILE__)
