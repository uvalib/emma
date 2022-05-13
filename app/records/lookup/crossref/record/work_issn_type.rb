# app/records/lookup/crossref/record/work_issn_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkIssnType
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkIssnType
#
class Lookup::Crossref::Record::WorkIssnType < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one  :type
    has_many :value
  end

end

__loading_end(__FILE__)
