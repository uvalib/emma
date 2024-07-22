# app/types/remediated_aspects.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - RemediationFields - RemediatedAspects
#
# @see "en.emma.type.search.RemediatedAspects"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/RemediationFields/rem_remediatedAspects  JSON schema specification
#
class RemediatedAspects < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
