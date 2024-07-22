# app/types/work_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# "Describes the type of work"
#
# @note Rejected for API 0.0.5
#
# @see "en.emma.type.search.WorkType"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/EmmaCommonFields/emma_workType   JSON schema specification
#
class WorkType < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
