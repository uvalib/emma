# app/types/remediation_status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - RemediationFields - RemediationStatus
#
# @see "en.emma.type.search.RemediationStatus"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/RemediationFields/rem_status   JSON schema specification
#
class RemediationStatus < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
