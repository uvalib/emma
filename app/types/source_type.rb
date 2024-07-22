# app/types/source_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - RemediationFields - SourceType
#
# @see "en.emma.type.search.SourceType"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/RemediationFields/rem_source   JSON schema specification
#
class SourceType < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
