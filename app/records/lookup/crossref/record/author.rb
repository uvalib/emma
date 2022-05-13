# app/records/lookup/crossref/record/author.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::Author
#
# @see https://api.crossref.org/swagger-ui/index.html#model-Author
#
class Lookup::Crossref::Record::Author < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :affiliation,          Lookup::Crossref::Record::Affiliation
    has_one  :authenticated_orcid,  Boolean
    has_one  :family
    has_one  :given
    has_one  :name
    has_one  :orcid
    has_one  :prefix
    has_one  :sequence
    has_one  :suffix
  end

end

__loading_end(__FILE__)
