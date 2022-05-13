# app/records/lookup/crossref/record/work_assertion.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkAssertion
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkAssertion
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Record::WorkAssertion < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :explanation, Lookup::Crossref::Record::WorksMessageMessageItemsAssertionExplanation
    has_one :group,       Lookup::Crossref::Record::WorksMessageMessageItemsAssertionGroup
    has_one :name
    has_one :order,       Integer
    has_one :url
    has_one :value
  end

end

__loading_end(__FILE__)
