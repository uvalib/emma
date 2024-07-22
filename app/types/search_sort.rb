# app/types/search_sort.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EMMA Unified Search API - SearchSort
#
# @see "en.emma.type.search.SearchSort"
# @see https://api.swaggerhub.com/apis/bus/emma-federated-search-api/0.0.5#/paths/search/get/parameters[name=sort]  JSON API specification
#
class SearchSort < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
