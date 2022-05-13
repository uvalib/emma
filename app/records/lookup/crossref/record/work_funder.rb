# app/records/lookup/crossref/record/work_funder.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkFunder
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkFunder
#
class Lookup::Crossref::Record::WorkFunder < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :award
    has_one  :doi
    has_one  :doi_asserted_by
    has_one  :name
  end

end

__loading_end(__FILE__)
