# app/types/search_group.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EMMA Unified Search API - SearchGroup
#
# === API description
# (EXPERIMENTAL) Search results will be grouped by the given field.  Result
# page size will automatically be limited to 10 maximum.  Each result will have
# a number of grouped records provided as children, so the number of records
# returned will be more than 10.  Cannot be combined with sorting by title or
# date.
#
# @see "en.emma.type.search.SearchGroup"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/Group  JSON schema specification
#
class SearchGroup < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
