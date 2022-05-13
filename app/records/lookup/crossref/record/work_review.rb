# app/records/lookup/crossref/record/work_review.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkReview
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkReview
#
class Lookup::Crossref::Record::WorkReview < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :competing_interest_statement
    has_one :language
    has_one :recommendation
    has_one :revision_round
    has_one :running_number
    has_one :stage
    has_one :type
  end

end

__loading_end(__FILE__)
