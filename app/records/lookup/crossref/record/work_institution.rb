# app/records/lookup/crossref/record/work_institution.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkInstitution
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkInstitution
#
class Lookup::Crossref::Record::WorkInstitution < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :acronym
    has_many :department
    has_one  :name
    has_many :place
  end

end

__loading_end(__FILE__)
