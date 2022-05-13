# app/records/lookup/crossref/record/works_message_message_items_assertion_group.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorksMessageMessageItemsAssertionGroup
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorksMessageMessageItemsAssertionGroup
#
#--
# noinspection RubyClassModuleNamingConvention, LongLine
#++
class Lookup::Crossref::Record::WorksMessageMessageItemsAssertionGroup < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :label
    has_one :name
  end

end

__loading_end(__FILE__)
