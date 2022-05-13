# app/records/lookup/crossref/record/works_message_message_items_assertion_explanation.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorksMessageMessageItemsAssertionExplanation
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorksMessageMessageItemsAssertionExplanation
#
#--
# noinspection RubyClassModuleNamingConvention, LongLine
#++
class Lookup::Crossref::Record::WorksMessageMessageItemsAssertionExplanation < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :issue
  end

end

__loading_end(__FILE__)
