# app/types/series_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# FRAME metadata - SeriesType
#
# @see "en.emma.type.search.SeriesType"
#
class SeriesType < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
